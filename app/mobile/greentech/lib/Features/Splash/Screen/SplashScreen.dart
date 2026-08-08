import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;

  late AnimationController _logoController;
  late Animation<double> _logoScale;
  late Animation<double> _logoOpacity;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _logoScale = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _logoController, curve: Curves.easeOutCubic),
    );

    _logoOpacity = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _logoController, curve: Curves.easeIn));

    _logoController.forward();

    _startLoading();
  }

  void _startLoading() {
    Timer.periodic(const Duration(milliseconds: 35), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_progress < 1.0) {
        setState(() {
          _progress += 0.025;
        });
      } else {
        timer.cancel();

        Future.delayed(const Duration(milliseconds: 400), () {
          if (!mounted) return;
          context.go('/auth');
        });
      }
    });
  }

  @override
  void dispose() {
    _logoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          SafeArea(
            child: Center(
              child: AnimatedBuilder(
                animation: _logoController,
                builder: (context, child) {
                  return Opacity(
                    opacity: _logoOpacity.value,
                    child: Transform.scale(
                      scale: _logoScale.value,
                      child: child,
                    ),
                  );
                },
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 90,
                      height: 90,
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: Colors.white,
                        size: 44,
                      ),
                    ),

                    const SizedBox(height: 32),

                    const Text(
                      'GreenTech',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 34,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.5,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Subtle subtitle
                    const Text(
                      'Innovating for a Sustainable Future',
                      style: TextStyle(
                        color: Color(0xFF8E8E93),
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.2,
                      ),
                    ),

                    const SizedBox(height: 48),

                    SizedBox(
                      width: 120,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: LinearProgressIndicator(
                          value: _progress,
                          minHeight: 2.5,
                          backgroundColor: const Color(0xFFE5E5EA),
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.black,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
