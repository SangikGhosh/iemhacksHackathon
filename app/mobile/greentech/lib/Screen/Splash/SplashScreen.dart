import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Screen/Auth/AuthSelectionScreen.dart';
import 'package:greentech/Screen/Onboarding/OnboardingScreen.dart';
import 'package:greentech/Utils/AppColors.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  static const _minimumVisible = Duration(milliseconds: 2600);

  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;
  late final Animation<double> _progress;

  bool _warmedImages = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_warmedImages) return;
    _warmedImages = true;
    precacheImage(authBackgroundImage, context);
  }

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: _minimumVisible);

    _scale = Tween<double>(begin: 0.88, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0, 0.6, curve: Curves.easeOutCubic),
      ),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0, 0.45, curve: Curves.easeIn),
    );

    _progress = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.1, 1, curve: Curves.easeInOut),
    );

    _controller.forward();
    _start();
  }

  Future<void> _start() async {
    final minimumVisible = Future<void>.delayed(_minimumVisible);
    final session = ref.read(sessionProvider.future);
    final onboarding = OnboardingService.hasSeen();

    var seenOnboarding = true;

    try {
      seenOnboarding = await onboarding;
    } catch (_) {
      seenOnboarding = false;
    }

    try {
      await session;
    } catch (_) {}

    await minimumVisible;

    if (!mounted) return;

    if (!seenOnboarding) {
      context.go('/onboarding');
      return;
    }

    context.go(ref.read(sessionProvider).value != null ? '/home' : '/auth');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        statusBarBrightness: Brightness.light,
        systemNavigationBarColor: appBackground,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
      child: Scaffold(
        backgroundColor: appBackground,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(width: double.infinity),

              const Spacer(),

              AnimatedBuilder(
                animation: _controller,
                builder: (context, child) => Opacity(
                  opacity: _opacity.value,
                  child: Transform.scale(scale: _scale.value, child: child),
                ),
                child: Image.asset(
                  'Assets/image/AppLogoMark.png',
                  width: 132,
                  height: 132,
                  fit: BoxFit.contain,
                  color: appInk,
                ),
              ),

              const Spacer(),

              FadeTransition(
                opacity: _opacity,
                child: SizedBox(
                  width: 132,
                  height: 4,
                  child: AnimatedBuilder(
                    animation: _progress,
                    builder: (context, child) => DecoratedBox(
                      decoration: BoxDecoration(
                        color: appInk.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FractionallySizedBox(
                          widthFactor: _progress.value.clamp(0.06, 1),
                          child: Container(
                            decoration: BoxDecoration(
                              color: appInk,
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 56),
            ],
          ),
        ),
      ),
    );
  }
}
