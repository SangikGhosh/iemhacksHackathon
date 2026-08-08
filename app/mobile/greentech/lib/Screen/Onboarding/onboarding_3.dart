import 'package:flutter/material.dart';

class OnboardingScreenTwo extends StatefulWidget {
  const OnboardingScreenTwo({super.key});

  @override
  State<OnboardingScreenTwo> createState() => _OnboardingScreenTwoState();
}

class _OnboardingScreenTwoState extends State<OnboardingScreenTwo> {
  // Page index set to 1 for the 2nd onboarding screen (middle dot active)
  final int _currentPage = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image (Forest Path)
          Image.asset('assets/images/forest_bg.jpg', fit: BoxFit.cover),

          // 2. Foreground Content Layer
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                children: [
                  const SizedBox(height: 8),

                  // Top Skip Button
                  Align(
                    alignment: Alignment.topRight,
                    child: GestureDetector(
                      onTap: () {},
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Text(
                          'Skip >',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Center Symbol (Star & Plant in Hand Icon)
                  Image.asset(
                    'assets/images/rewards_icon.png',
                    width: 140,
                    height: 140,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 36),

                  // Title Text
                  const Text(
                    'Earn\nRewards',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle Text
                  const Text(
                    'Segregate waste correctly\nand earn points for your efforts.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Bottom Page Indicator Dots (Middle dot active)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(3, (index) {
                      final isActive = index == _currentPage;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isActive ? 10 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isActive
                              ? Colors.white
                              : Colors.white.withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                      );
                    }),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
