import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hugeicons/hugeicons.dart';

import 'package:greentech/Provider/SignupProvider.dart';
import 'package:greentech/Widget/AuthWidgets/AuthShell.dart';
import 'package:greentech/Widget/AuthWidgets/OtpInput.dart';
import 'package:greentech/Widget/AuthWidgets/PasswordChecklist.dart';
import 'package:greentech/Widget/UiKit.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _emailController = TextEditingController();
  final _nameController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _showEmailError = false;
  bool _showPasswordError = false;

  SignupController get notifier => ref.read(signupProvider.notifier);

  @override
  void dispose() {
    _emailController.dispose();
    _nameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    final state = ref.read(signupProvider);

    if (state.step == SignupStep.email && !state.canAdvance) {
      setState(() => _showEmailError = true);
      return;
    }
    if (state.step == SignupStep.password && !state.canAdvance) {
      setState(() => _showPasswordError = true);
      return;
    }
    if (!state.canAdvance) return;

    FocusScope.of(context).unfocus();
    final session = await notifier.next();

    if (session != null && mounted) context.go('/home');
  }

  void _back() {
    if (ref.read(signupProvider).isFirstStep) {
      context.go('/auth');
      return;
    }
    FocusScope.of(context).unfocus();
    notifier.back();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(signupProvider);
    final total = SignupStep.values.length;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AuthShell(
        onBack: _back,
        stepLabel: 'Step ${state.stepIndex + 1} of $total',
        actions: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UiPrimaryButton(
              label: state.isLastStep ? 'Create account' : 'Continue',
              busy: state.busy,
              onTap: state.canAdvance ? _next : null,
            ),
            if (state.step == SignupStep.otp) ...[
              const SizedBox(height: 12),
              const _ResendButton(),
            ],
          ],
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 280),
          switchInCurve: uiEase,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (current, previous) => Stack(
            alignment: Alignment.topLeft,
            children: [...previous, if (current != null) current],
          ),
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.06, 0),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: _buildStep(state),
        ),
      ),
    );
  }

  Widget _buildStep(SignupState state) {
    return switch (state.step) {
      SignupStep.email => _EmailStep(
        key: const ValueKey(SignupStep.email),
        field: _emailController,
        showError: _showEmailError,
        onChanged: (value) {
          notifier.setEmail(value);
          if (_showEmailError) setState(() => _showEmailError = false);
        },
        onSubmitted: (_) => _next(),
      ),
      SignupStep.otp => _OtpStep(
        key: const ValueKey(SignupStep.otp),
        onComplete: _next,
      ),
      SignupStep.name => _NameStep(
        key: const ValueKey(SignupStep.name),
        field: _nameController,
        onSubmitted: (_) => _next(),
      ),
      SignupStep.password => _PasswordStep(
        key: const ValueKey(SignupStep.password),
        field: _passwordController,
        showError: _showPasswordError,
        onChanged: (value) {
          notifier.setPassword(value);
          if (_showPasswordError) setState(() => _showPasswordError = false);
        },
        onSubmitted: (_) => _next(),
      ),
    };
  }
}

class _EmailStep extends ConsumerWidget {
  const _EmailStep({
    super.key,
    required this.field,
    required this.showError,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController field;
  final bool showError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeadline(
          'What’s your email?',
          subtitle: 'We’ll send a six-digit code to confirm it’s really you.',
        ),
        const SizedBox(height: 30),
        _Listenable(
          field: field,
          onChanged: onChanged,
          builder: () => UiTextField(
            label: 'Email address',
            controller: field,
            hint: 'you@example.com',
            enabled: !state.busy,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.email],
            errorText: showError && !isValidEmail(field.text)
                ? 'Enter a valid email address.'
                : null,
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(height: 18),
        const AuthFootnote(
          'Your address is never shown to other members of the community.',
        ),
        UiErrorNote(state.error),
      ],
    );
  }
}

class _OtpStep extends ConsumerWidget {
  const _OtpStep({super.key, required this.onComplete});

  final VoidCallback onComplete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupProvider);
    final notifier = ref.read(signupProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeadline('Enter your code'),
        const SizedBox(height: 10),
        Text.rich(
          TextSpan(
            style: const TextStyle(
              fontSize: 15.5,
              height: 1.45,
              color: uiInkSecondary,
              letterSpacing: -0.2,
            ),
            children: [
              const TextSpan(text: 'We sent a 6-digit code to '),
              TextSpan(
                text: state.email,
                style: const TextStyle(
                  color: uiInk,
                  fontWeight: FontWeight.w700,
                ),
              ),
              TextSpan(text: '. It expires in ${otpValidity.inMinutes} min.'),
            ],
          ),
        ),
        const SizedBox(height: 28),
        OtpBoxes(value: state.otp, hasError: state.error != null),
        UiErrorNote(state.error),
        const SizedBox(height: 26),
        NumericKeypad(
          enabled: !state.busy,
          onDigit: (digit) {
            notifier.appendOtpDigit(digit);
            if (ref.read(signupProvider).otp.length == 6) {
              Future.delayed(const Duration(milliseconds: 180), onComplete);
            }
          },
          onBackspace: notifier.deleteOtpDigit,
        ),
      ],
    );
  }
}

class _ResendButton extends ConsumerWidget {
  const _ResendButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupProvider);
    final waiting = state.resendSeconds > 0;

    return Pressable(
      onTap: state.canResend
          ? ref.read(signupProvider.notifier).resendOtp
          : null,
      scale: 0.98,
      child: Container(
        height: 48,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            HugeIcon(
              icon: HugeIcons.strokeRoundedRefresh,
              color: waiting ? uiInkTertiary : uiInk,
              size: 17,
            ),
            const SizedBox(width: 9),
            Text(
              waiting ? 'Resend in ${state.resendSeconds}s' : 'Resend code',
              style: TextStyle(
                fontSize: 14.5,
                fontWeight: FontWeight.w600,
                color: waiting ? uiInkTertiary : uiInk,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NameStep extends ConsumerWidget {
  const _NameStep({super.key, required this.field, required this.onSubmitted});

  final TextEditingController field;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeadline(
          'What’s your name?',
          subtitle: 'This is how collectors will recognise you.',
        ),
        const SizedBox(height: 30),
        _Listenable(
          field: field,
          onChanged: ref.read(signupProvider.notifier).setFullName,
          builder: () => UiTextField(
            label: 'Full name',
            controller: field,
            hint: 'Alex Smith',
            enabled: !state.busy,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.name],
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(height: 18),
        const AuthFootnote(
          'We’ll only show this to people you interact with on Green Route.',
        ),
        UiErrorNote(state.error),
      ],
    );
  }
}

class _PasswordStep extends ConsumerWidget {
  const _PasswordStep({
    super.key,
    required this.field,
    required this.showError,
    required this.onChanged,
    required this.onSubmitted,
  });

  final TextEditingController field;
  final bool showError;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(signupProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const AuthHeadline(
          'Create a password',
          subtitle: 'One last step and your account is ready.',
        ),
        const SizedBox(height: 30),
        _Listenable(
          field: field,
          onChanged: onChanged,
          builder: () => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              UiTextField(
                label: 'Password',
                controller: field,
                hint: 'At least 8 characters',
                obscure: true,
                enabled: !state.busy,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                inputFormatters: [LengthLimitingTextInputFormatter(72)],
                errorText: showError ? passwordIssue(field.text) : null,
                onSubmitted: onSubmitted,
              ),
              const SizedBox(height: 20),
              PasswordChecklist(password: field.text),
            ],
          ),
        ),
        UiErrorNote(state.error),
      ],
    );
  }
}

class _Listenable extends StatefulWidget {
  const _Listenable({
    required this.field,
    required this.onChanged,
    required this.builder,
  });

  final TextEditingController field;
  final ValueChanged<String> onChanged;
  final Widget Function() builder;

  @override
  State<_Listenable> createState() => _ListenableState();
}

class _ListenableState extends State<_Listenable> {
  @override
  void initState() {
    super.initState();
    widget.field.addListener(_handle);
  }

  void _handle() {
    widget.onChanged(widget.field.text);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.field.removeListener(_handle);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder();
}
