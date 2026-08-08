import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greentech/Config/ApiConfig.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/ToastService.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Widget/AuthControls.dart';
import 'package:greentech/Widget/AuthField.dart';
import 'package:greentech/Widget/AuthShell.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();

  bool _busy = false;
  bool _showErrors = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_onChanged);
    _passwordController.addListener(_onChanged);
  }

  void _onChanged() {
    if (!mounted) return;
    setState(() {
      if (_error != null) _error = null;
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  bool get _isComplete =>
      _emailController.text.trim().isNotEmpty &&
      _passwordController.text.isNotEmpty;

  bool get _isValid =>
      _emailPattern.hasMatch(_emailController.text.trim()) &&
      _passwordController.text.isNotEmpty;

  static final _emailPattern = RegExp(
    r'^[\w.!#$%&’*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$',
  );

  Future<void> _submit() async {
    if (!_isValid) {
      setState(() => _showErrors = true);
      return;
    }

    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final session = await ApiService.login(
        email: _emailController.text,
        password: _passwordController.text,
      );
      await ref.read(sessionProvider.notifier).adopt(session);
      if (mounted) context.go('/dashboard');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      progress: _isComplete ? 1 : 0.5,
      footer: const _SignupPrompt(),
      bottomBar: StepNavBar(
        onBack: () => context.go('/auth'),
        next: NextButton(
          enabled: _isComplete,
          busy: _busy,
          semanticLabel: 'Sign in',
          onPressed: _submit,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const StepHeadline(
            'Welcome back',
            subtitle: 'Sign in to pick up where you left off.',
          ),
          const SizedBox(height: 24),
          AutofillGroup(
            child: Column(
              children: [
                AuthField(
                  label: 'Email address',
                  controller: _emailController,
                  hint: 'you@example.com',
                  autofocus: true,
                  enabled: !_busy,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  errorText:
                      _showErrors &&
                          !_emailPattern.hasMatch(_emailController.text.trim())
                      ? 'Enter a valid email address.'
                      : null,
                  onSubmitted: (_) => _passwordFocus.requestFocus(),
                ),
                const SizedBox(height: 12),
                AuthField(
                  label: 'Password',
                  controller: _passwordController,
                  hint: 'Your password',
                  obscure: true,
                  enabled: !_busy,
                  focusNode: _passwordFocus,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.password],
                  errorText: _showErrors && _passwordController.text.isEmpty
                      ? 'Enter your password.'
                      : null,
                  onSubmitted: (_) => _submit(),
                ),
              ],
            ),
          ),
          ErrorNote(_error),
          if (ApiConfig.isGoogleEnabled) ...[
            const SizedBox(height: 26),
            const _OrDivider(),
            const SizedBox(height: 18),
            PillButton(
              label: 'Continue with Google',
              filled: false,
              onPressed: _busy ? null : _signInWithGoogle,
              icon: Icon(
                Icons.g_mobiledata_rounded,
                size: 26,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
          const SizedBox(height: 20),
          const PrivacyNote(
            'We’ll email you whenever a new device signs in to your account.',
          ),
        ],
      ),
    );
  }

  Future<void> _signInWithGoogle() async {
    ToastService.show(
      'Google sign-in is not configured yet. Use email for now.',
      ToastType.info,
      context,
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).colorScheme.outlineVariant;

    return Row(
      children: [
        Expanded(child: Divider(color: line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text('or', style: captionStyle(context)),
        ),
        Expanded(child: Divider(color: line, height: 1)),
      ],
    );
  }
}

class _SignupPrompt extends StatelessWidget {
  const _SignupPrompt();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.go('/signup'),
      behavior: HitTestBehavior.opaque,
      child: Text.rich(
        TextSpan(
          style: captionStyle(context),
          children: [
            const TextSpan(text: 'New to GreenTech? '),
            TextSpan(
              text: 'Create an account',
              style: captionStyle(context).copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
              ),
            ),
          ],
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
