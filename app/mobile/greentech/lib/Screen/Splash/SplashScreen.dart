import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:greentech/Provider/SessionProvider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _minimumVisible = Duration(milliseconds: 1400);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _progress;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _minimumVisible);

    _scale = Tween<double>(begin: 0.94, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.55, curve: Curves.easeOutCubic),
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.4, curve: Curves.easeIn),
    );

    _progress = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);

    _controller.forward();
    _start();
  }

  Future<void> _start() async {
    await Future.wait([
      ref.read(sessionProvider.future),
      _controller.forward().orCancel.catchError((_) {}),
    ]);

    if (!mounted) return;
    context.go(ref.read(sessionProvider).value != null ? '/home' : '/auth');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('Assets/image/splash_bg.png', fit: BoxFit.cover),
          // Animated Content Layer
          SafeArea(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) => Opacity(
                opacity: _opacity.value,
                child: Transform.scale(scale: _scale.value, child: child),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 30),

                  // Logo
                  Image.asset('Assets/image/logo.png', width: 190),

                  const SizedBox(height: 5),

                  // Title
                  const Text(
                    'GreenRoute',
                    style: TextStyle(
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF159447),
                    ),
                  ),

                  // Tagline
                  const Text(
                    '—  WASTE SMART  |  CITY CLEAN  |  FUTURE GREEN  —',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Color(0xFF14517A),
                    ),
                  ),

                  const Spacer(),

                  // Subtitle
                  const Text(
                    'Together for a\nCleaner Today, Greener Tomorrow.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF333333),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Animated Progress Bar bound to Riverpod animation controller
                  SizedBox(
                    width: 160,
                    height: 6,
                    child: AnimatedBuilder(
                      animation: _progress,
                      builder: (context, _) => Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFD8E8D5),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: FractionallySizedBox(
                            widthFactor: _progress.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFF3FAE2A),
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 35),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
