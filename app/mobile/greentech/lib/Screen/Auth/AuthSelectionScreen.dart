import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greentech/Config/ApiConfig.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/GoogleAuthService.dart';
import 'package:greentech/Service/ToastService.dart';

import 'package:greentech/Widget/GoogleMark.dart';
import 'package:greentech/Widget/UiKit.dart';

const AssetImage authBackgroundImage = AssetImage(
  'Assets/image/AuthScreenImage.jpg',
);

class AuthSelectionScreen extends ConsumerStatefulWidget {
  const AuthSelectionScreen({super.key});

  @override
  ConsumerState<AuthSelectionScreen> createState() =>
      _AuthSelectionScreenState();
}

class _AuthSelectionScreenState extends ConsumerState<AuthSelectionScreen> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.black,
        systemNavigationBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Color(0xFF101512), child: SizedBox.expand()),

            Image(
              image: authBackgroundImage,
              fit: BoxFit.cover,
              frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                if (wasSynchronouslyLoaded) return child;
                return AnimatedOpacity(
                  opacity: frame == null ? 0 : 1,
                  duration: const Duration(milliseconds: 260),
                  curve: Curves.easeOut,
                  child: child,
                );
              },
            ),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x5C000000),
                    Color(0x2E000000),
                    Color(0x2E000000),
                    Color(0xA6000000),
                  ],
                  stops: [0, 0.28, 0.82, 1],
                ),
              ),
              child: SizedBox.expand(),
            ),

            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Spacer(flex: 3),
                    const _HeaderLogo(),
                    const SizedBox(height: 18),
                    const Text(
                      'Manage your waste,\nbuild our future.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 25,
                        fontWeight: FontWeight.w200,
                        letterSpacing: -0.6,
                        height: 1.28,
                      ),
                    ),
                    const Spacer(flex: 2),
                    _SolidButton(
                      label: 'Get started',
                      backgroundColor: Colors.white,
                      textColor: uiInk,
                      onPressed: () => context.push('/signup'),
                    ),
                    const SizedBox(height: 12),
                    _SolidButton(
                      label: 'I already have an account',
                      backgroundColor: Colors.black,
                      textColor: Colors.white,
                      onPressed: () => context.push('/login'),
                    ),
                    const SizedBox(height: 18),
                    const _OrDivider(),
                    const SizedBox(height: 18),
                    _SolidButton(
                      label: _busy ? 'Signing in…' : 'Continue with Google',
                      backgroundColor: Colors.white,
                      textColor: uiInk,
                      leading: const GoogleMark(size: 20),
                      onPressed: _busy ? null : _continueWithGoogle,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'By continuing you agree to keep the community clean.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: Colors.white.withValues(alpha: 0.74),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _continueWithGoogle() async {
    if (!ApiConfig.isGoogleEnabled) {
      ToastService.show(
        'Google sign-in is not configured yet.',
        ToastType.info,
        context,
      );
      return;
    }

    setState(() => _busy = true);

    try {
      final idToken = await GoogleAuthService.signIn();
      final session = await ApiService.loginWithGoogle(idToken: idToken);
      await ref.read(sessionProvider.notifier).adopt(session);
      if (mounted) context.go('/home');
    } on GoogleAuthCancelled {
      return;
    } on GoogleAuthException catch (e) {
      if (mounted) ToastService.show(e.message, ToastType.error, context);
    } on ApiException catch (e) {
      if (mounted) ToastService.show(e.message, ToastType.error, context);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    final line = Colors.white.withValues(alpha: 0.35);

    return Row(
      children: [
        Expanded(child: Divider(color: line, height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Text(
            'or',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.8),
              fontSize: 13,
            ),
          ),
        ),
        Expanded(child: Divider(color: line, height: 1)),
      ],
    );
  }
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'Assets/image/AppLogoMark.png',
          width: 34,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        const Text(
          'Green Route',
          style: TextStyle(
            color: Colors.white,
            fontSize: 36,
            fontWeight: FontWeight.w700,
            letterSpacing: -1.4,
          ),
        ),
      ],
    );
  }
}

class _SolidButton extends StatelessWidget {
  const _SolidButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.leading,
  });

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 16.5,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.2,
      ),
    );

    return Pressable(
      onTap: onPressed,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(28),
        ),
        child: leading == null
            ? text
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [leading!, const SizedBox(width: 12), text],
              ),
      ),
    );
  }
}
