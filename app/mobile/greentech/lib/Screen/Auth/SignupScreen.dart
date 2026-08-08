import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greentech/Provider/SignupProvider.dart';
import 'package:greentech/Widget/AuthControls.dart';
import 'package:greentech/Widget/AuthField.dart';
import 'package:greentech/Widget/AuthShell.dart';
import 'package:greentech/Widget/OtpInput.dart';

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

    if (session != null && mounted) {
      context.go('/dashboard');
    }
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

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: AuthShell(
        progress: state.progress,
        footer: const _SupportLine(),
        bottomBar: StepNavBar(
          onBack: _back,
          middle: state.step == SignupStep.otp ? const _ResendButton() : null,
          next: NextButton(
            enabled: state.canAdvance,
            busy: state.busy,
            icon: state.isLastStep
                ? Icons.check_rounded
                : Icons.arrow_forward_rounded,
            semanticLabel: state.isLastStep ? 'Create account' : 'Continue',
            onPressed: _next,
          ),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 260),
          switchInCurve: Curves.easeOutCubic,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeadline("What's your email?"),
        const SizedBox(height: 24),
        _Listenable(
          field: field,
          onChanged: onChanged,
          builder: () => AuthField(
            label: 'Email address',
            controller: field,
            hint: 'you@example.com',
            autofocus: true,
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
        const SizedBox(height: 14),
        const PrivacyNote(
          'We’ll send a six-digit code to confirm it’s really you. '
          'Your address is never shown to other members.',
        ),
        ErrorNote(state.error),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeadline('We just emailed you,\nwhat’s the code?'),
        const SizedBox(height: 24),
        OtpBoxes(value: state.otp, hasError: state.error != null),
        const SizedBox(height: 16),
        RichText(
          text: TextSpan(
            style: captionStyle(context),
            children: [
              const TextSpan(text: 'We’ve sent a 6-digit code to '),
              TextSpan(
                text: state.email,
                style: captionStyle(context).copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(
                text:
                    '. It expires in '
                    '${otpValidity.inMinutes} minutes.',
              ),
            ],
          ),
        ),
        ErrorNote(state.error),
        const SizedBox(height: 22),
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
    final colors = Theme.of(context).colorScheme;
    final state = ref.watch(signupProvider);
    final waiting = state.resendSeconds > 0;

    return TextButton.icon(
      onPressed: state.canResend
          ? ref.read(signupProvider.notifier).resendOtp
          : null,
      style: TextButton.styleFrom(
        foregroundColor: colors.onSurface,
        disabledForegroundColor: colors.outline,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(
            color: state.canResend
                ? colors.surfaceContainerHighest
                : colors.outlineVariant,
          ),
        ),
      ),
      icon: const Icon(Icons.refresh_rounded, size: 16),
      label: Text(
        waiting ? 'Resend in ${state.resendSeconds}s' : 'Resend code',
        style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeadline("What's your name?"),
        const SizedBox(height: 24),
        _Listenable(
          field: field,
          onChanged: ref.read(signupProvider.notifier).setFullName,
          builder: () => AuthField(
            label: 'Full name',
            controller: field,
            hint: 'Alex Smith',
            autofocus: true,
            enabled: !state.busy,
            keyboardType: TextInputType.name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.done,
            autofillHints: const [AutofillHints.name],
            inputFormatters: [LengthLimitingTextInputFormatter(100)],
            onSubmitted: onSubmitted,
          ),
        ),
        const SizedBox(height: 14),
        const PrivacyNote(
          'We’ll only show this to people you interact with on GreenTech.',
        ),
        ErrorNote(state.error),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const StepHeadline('Create a password'),
        const SizedBox(height: 24),
        _Listenable(
          field: field,
          onChanged: onChanged,
          builder: () => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AuthField(
                label: 'Password',
                controller: field,
                hint: 'At least 8 characters',
                obscure: true,
                autofocus: true,
                enabled: !state.busy,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.newPassword],
                inputFormatters: [LengthLimitingTextInputFormatter(72)],
                errorText: showError ? passwordIssue(field.text) : null,
                onSubmitted: onSubmitted,
              ),
              const SizedBox(height: 14),
              PasswordStrengthBar(password: field.text),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const PrivacyNote(
          'Use 8 to 72 characters. Mixing letters, numbers and symbols makes '
          'your account harder to break into.',
        ),
        ErrorNote(state.error),
      ],
    );
  }
}

class _SupportLine extends StatelessWidget {
  const _SupportLine();

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: captionStyle(context),
        children: [
          const TextSpan(text: 'Experiencing issues? Email our team: '),
          TextSpan(
            text: 'community@greentech.app',
            style: captionStyle(context).copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
      textAlign: TextAlign.center,
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
