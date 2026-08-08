import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greentech/Config/ApiConfig.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/GoogleAuthService.dart';
import 'package:greentech/Service/ToastService.dart';

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
    SystemChrome.setSystemUIOverlayStyle(SystemUiOverlayStyle.light);

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('Assets/image/AuthScreenImage.jpg', fit: BoxFit.cover),

          Container(color: Colors.black.withValues(alpha: 0.4)),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Column(
                children: [
                  const Spacer(flex: 3),

                  const _HeaderLogo(),
                  const SizedBox(height: 12),
                  const Text(
                    'Manage Your Waste,\nBuild Our Future.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),

                  const Spacer(flex: 2),

                  _SolidButton(
                    label: 'Get Started',
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                    onPressed: () => context.push('/signup'),
                  ),
                  const SizedBox(height: 16),
                  _SolidButton(
                    label: 'Let’s Get Back In',
                    backgroundColor: Colors.black,
                    textColor: Colors.white,
                    onPressed: () => context.push('/login'),
                  ),

                  const SizedBox(height: 20),
                  const _OrDivider(),
                  const SizedBox(height: 20),

                  _SolidButton(
                    label: _busy ? 'Signing in…' : 'Continue with Google',
                    backgroundColor: Colors.white,
                    textColor: Colors.black,
                    leading: const _GoogleMark(size: 20),
                    onPressed: _busy ? null : _continueWithGoogle,
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ],
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

class _GoogleMark extends StatelessWidget {
  const _GoogleMark({this.size = 20});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _GoogleMarkPainter()),
    );
  }
}

class _GoogleMarkPainter extends CustomPainter {
  static const _viewBox = 48.0;

  static const _paths = <String, Color>{
    'M45.12 24.5c0-1.56-.14-3.06-.4-4.5H24v8.51h11.84c-.51 2.75-2.06 5.08-4.39 6.64v5.52h7.11c4.16-3.83 6.56-9.47 6.56-16.17z':
        Color(0xFF4285F4),
    'M24 46c5.94 0 10.92-1.97 14.56-5.33l-7.11-5.52c-1.97 1.32-4.49 2.1-7.45 2.1-5.73 0-10.58-3.87-12.31-9.07H4.34v5.7C7.96 41.07 15.4 46 24 46z':
        Color(0xFF34A853),
    'M11.69 28.18C11.25 26.86 11 25.45 11 24s.25-2.86.69-4.18v-5.7H4.34C2.85 17.09 2 20.45 2 24s.85 6.91 2.34 9.88l7.35-5.7z':
        Color(0xFFFBBC05),
    'M24 10.75c3.23 0 6.13 1.11 8.41 3.29l6.31-6.31C34.91 4.18 29.93 2 24 2 15.4 2 7.96 6.93 4.34 14.12l7.35 5.7c1.73-5.2 6.58-9.07 12.31-9.07z':
        Color(0xFFEA4335),
  };

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.scale(size.width / _viewBox, size.height / _viewBox);

    _paths.forEach((data, color) {
      canvas.drawPath(_parsePath(data), Paint()..color = color);
    });

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

final _tokenPattern = RegExp(r'[MmLlHhVvCcSsZz]|-?\d*\.?\d+');

Path _parsePath(String data) {
  final path = Path();
  final tokens = _tokenPattern.allMatches(data).map((m) => m[0]!).toList();

  double x = 0, y = 0, startX = 0, startY = 0, ctrlX = 0, ctrlY = 0;
  String command = '';
  var i = 0;

  double next() => double.parse(tokens[i++]);

  while (i < tokens.length) {
    final token = tokens[i];
    if (RegExp(r'[A-Za-z]').hasMatch(token)) {
      command = token;
      i++;
      if (command == 'Z' || command == 'z') {
        path.close();
        x = startX;
        y = startY;
        continue;
      }
    }

    final relative = command == command.toLowerCase();
    final originX = relative ? x : 0.0;
    final originY = relative ? y : 0.0;

    switch (command.toUpperCase()) {
      case 'M':
        x = originX + next();
        y = originY + next();
        path.moveTo(x, y);
        startX = x;
        startY = y;
        command = relative ? 'l' : 'L';
      case 'L':
        x = originX + next();
        y = originY + next();
        path.lineTo(x, y);
      case 'H':
        x = originX + next();
        path.lineTo(x, y);
      case 'V':
        y = originY + next();
        path.lineTo(x, y);
      case 'C':
        final x1 = originX + next();
        final y1 = originY + next();
        final x2 = originX + next();
        final y2 = originY + next();
        x = originX + next();
        y = originY + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        ctrlX = x2;
        ctrlY = y2;
      case 'S':
        final x1 = 2 * x - ctrlX;
        final y1 = 2 * y - ctrlY;
        final x2 = originX + next();
        final y2 = originY + next();
        x = originX + next();
        y = originY + next();
        path.cubicTo(x1, y1, x2, y2, x, y);
        ctrlX = x2;
        ctrlY = y2;
      default:
        i++;
    }
  }

  return path;
}

class _HeaderLogo extends StatelessWidget {
  const _HeaderLogo();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(shape: BoxShape.circle),
          child: const Icon(
            Icons.recycling_rounded,
            color: Colors.white,
            size: 48,
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'EcoCycle',
          style: TextStyle(
            color: Colors.white,
            fontSize: 32,
            fontWeight: FontWeight.w800,
            letterSpacing: -1.0,
          ),
        ),
      ],
    );
  }
}

class _SolidButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color textColor;
  final VoidCallback? onPressed;
  final Widget? leading;

  const _SolidButton({
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    required this.onPressed,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    final text = Text(
      label,
      style: TextStyle(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );

    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: double.infinity,
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(30),
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
