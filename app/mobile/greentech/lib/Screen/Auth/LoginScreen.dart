import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greentech/Config/ApiConfig.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/GoogleAuthService.dart';
import 'package:greentech/Widget/AuthWidgets/AuthShell.dart';
import 'package:greentech/Widget/GoogleMark.dart';
import 'package:greentech/Widget/UiKit.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  static final _emailPattern = RegExp(
    r'^[\w.!#$%&’*+/=?^`{|}~-]+@[\w-]+(\.[\w-]+)+$',
  );

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
      if (mounted) context.go('/home');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    FocusScope.of(context).unfocus();
    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final idToken = await GoogleAuthService.signIn();
      final session = await ApiService.loginWithGoogle(idToken: idToken);
      await ref.read(sessionProvider.notifier).adopt(session);
      if (mounted) context.go('/home');
    } on GoogleAuthCancelled {
      return;
    } on GoogleAuthException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      onBack: () => context.go('/auth'),
      actions: UiPrimaryButton(
        label: 'Sign in',
        busy: _busy,
        onTap: _isComplete ? _submit : null,
      ),
      footer: AuthSwitchPrompt(
        question: 'New to Green Route?',
        action: 'Create an account',
        onTap: () => context.go('/signup'),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AuthHeadline(
            'Welcome back',
            subtitle: 'Sign in to pick up where you left off.',
          ),
          const SizedBox(height: 30),
          AutofillGroup(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                UiTextField(
                  label: 'Email address',
                  controller: _emailController,
                  hint: 'you@example.com',
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
                const SizedBox(height: 18),
                UiTextField(
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
          UiErrorNote(_error),
          if (ApiConfig.isGoogleEnabled) ...[
            const SizedBox(height: 28),
            const UiOrDivider(),
            const SizedBox(height: 20),
            UiSecondaryButton(
              label: 'Continue with Google',
              onTap: _busy ? null : _signInWithGoogle,
              leading: const GoogleMark(size: 20),
            ),
          ],
          const SizedBox(height: 26),
          const AuthFootnote(
            'We’ll email you whenever a new device signs in to your account.',
          ),
        ],
      ),
    );
  }
}
