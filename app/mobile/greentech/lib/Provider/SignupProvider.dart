import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Service/ApiService.dart';

enum SignupStep { email, otp, name, password }

const Duration otpValidity = Duration(minutes: 10);
const Duration otpResendCooldown = Duration(seconds: 45);

final _emailPattern = RegExp(r'^[\w.!#$%&’*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$');

bool isValidEmail(String value) => _emailPattern.hasMatch(value.trim());

String? passwordIssue(String value) {
  if (value.length < 8) return 'Use at least 8 characters.';
  if (value.length > 72) return 'Keep it to 72 characters or fewer.';
  return null;
}

class SignupState {
  const SignupState({
    this.step = SignupStep.email,
    this.email = '',
    this.otp = '',
    this.fullName = '',
    this.password = '',
    this.busy = false,
    this.error,
    this.resendSeconds = 0,
  });

  final SignupStep step;
  final String email;
  final String otp;
  final String fullName;
  final String password;
  final bool busy;
  final String? error;
  final int resendSeconds;

  int get stepIndex => SignupStep.values.indexOf(step);
  double get progress => (stepIndex + 1) / SignupStep.values.length;
  bool get isFirstStep => step == SignupStep.email;
  bool get isLastStep => step == SignupStep.password;
  bool get canResend => resendSeconds == 0 && !busy;

  bool get canAdvance => switch (step) {
    SignupStep.email => isValidEmail(email),
    SignupStep.otp => otp.length == 6,
    SignupStep.name =>
      fullName.trim().length >= 2 && fullName.trim().length <= 100,
    SignupStep.password => passwordIssue(password) == null,
  };

  SignupState copyWith({
    SignupStep? step,
    String? email,
    String? otp,
    String? fullName,
    String? password,
    bool? busy,
    String? error,
    bool clearError = false,
    int? resendSeconds,
  }) {
    return SignupState(
      step: step ?? this.step,
      email: email ?? this.email,
      otp: otp ?? this.otp,
      fullName: fullName ?? this.fullName,
      password: password ?? this.password,
      busy: busy ?? this.busy,
      error: clearError ? null : (error ?? this.error),
      resendSeconds: resendSeconds ?? this.resendSeconds,
    );
  }
}

class SignupController extends Notifier<SignupState> {
  Timer? _cooldownTimer;

  @override
  SignupState build() {
    ref.onDispose(() => _cooldownTimer?.cancel());
    return const SignupState();
  }

  void setEmail(String value) =>
      state = state.copyWith(email: value, clearError: true);

  void setFullName(String value) =>
      state = state.copyWith(fullName: value, clearError: true);

  void setPassword(String value) =>
      state = state.copyWith(password: value, clearError: true);

  void appendOtpDigit(String digit) {
    if (state.otp.length >= 6) return;
    state = state.copyWith(otp: state.otp + digit, clearError: true);
  }

  void deleteOtpDigit() {
    if (state.otp.isEmpty) return;
    state = state.copyWith(
      otp: state.otp.substring(0, state.otp.length - 1),
      clearError: true,
    );
  }

  Future<AuthSession?> next() async {
    if (!state.canAdvance || state.busy) return null;

    switch (state.step) {
      case SignupStep.email:
        if (await _requestOtp()) _goTo(SignupStep.otp);
        return null;

      case SignupStep.otp:
        _goTo(SignupStep.name);
        return null;

      case SignupStep.name:
        _goTo(SignupStep.password);
        return null;

      case SignupStep.password:
        return _submit();
    }
  }

  void back() {
    if (state.isFirstStep || state.busy) return;
    _goTo(SignupStep.values[state.stepIndex - 1]);
  }

  Future<void> resendOtp() async {
    if (!state.canResend) return;
    if (await _requestOtp()) state = state.copyWith(otp: '');
  }

  Future<bool> _requestOtp() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      await ApiService.sendOtp(state.email);
      _startCooldown();
      return true;
    } on ApiException catch (e) {
      state = state.copyWith(error: e.message);
      return false;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  Future<AuthSession?> _submit() async {
    state = state.copyWith(busy: true, clearError: true);
    try {
      final session = await ApiService.register(
        email: state.email,
        fullName: state.fullName,
        password: state.password,
        otp: state.otp,
        role: Role.citizen,
      );
      await ref.read(sessionProvider.notifier).adopt(session);
      return session;
    } on ApiException catch (e) {
      if (_looksLikeOtpProblem(e.message)) {
        state = state.copyWith(error: e.message, otp: '', step: SignupStep.otp);
      } else if (_looksLikeEmailProblem(e.message)) {
        state = state.copyWith(error: e.message, step: SignupStep.email);
      } else {
        state = state.copyWith(error: e.message);
      }
      return null;
    } finally {
      state = state.copyWith(busy: false);
    }
  }

  bool _looksLikeOtpProblem(String message) =>
      message.toLowerCase().contains('otp');

  bool _looksLikeEmailProblem(String message) {
    final lower = message.toLowerCase();
    return lower.contains('email already in use') || lower.startsWith('email:');
  }

  void _goTo(SignupStep step) =>
      state = state.copyWith(step: step, clearError: true);

  void _startCooldown() {
    _cooldownTimer?.cancel();
    state = state.copyWith(resendSeconds: otpResendCooldown.inSeconds);

    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final remaining = state.resendSeconds - 1;
      if (remaining <= 0) timer.cancel();
      state = state.copyWith(resendSeconds: remaining < 0 ? 0 : remaining);
    });
  }
}

final signupProvider =
    NotifierProvider.autoDispose<SignupController, SignupState>(
      SignupController.new,
    );
