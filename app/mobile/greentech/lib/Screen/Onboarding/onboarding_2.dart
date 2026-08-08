import 'package:flutter/material.dart';

class OnboardingScreenThree extends StatefulWidget {
  const OnboardingScreenThree({super.key});

  @override
  State<OnboardingScreenThree> createState() => _OnboardingScreenThreeState();
}

class _OnboardingScreenThreeState extends State<OnboardingScreenThree> {
  // Page index set to 2 for the 3rd onboarding screen
  final int _currentPage = 2;
  final int _totalPages = 4;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Background Image (Tree against Sky)
          Image.asset('assets/images/tree_sky_bg.jpg', fit: BoxFit.cover),

          // Dark overlay to match the moody blue tone & improve contrast
          Container(color: Colors.black.withOpacity(0.25)),

          // 2. Foreground UI Layer
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),

                  const Spacer(flex: 2),

                  // Center Symbol (Smart Truck Icon)
                  Image.asset(
                    'assets/images/smart_truck_icon.png',
                    width: 150,
                    height: 150,
                    fit: BoxFit.contain,
                  ),

                  const SizedBox(height: 32),

                  // Title Text
                  const Text(
                    'Smart Collection',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 38,
                      height: 1.15,
                      fontWeight: FontWeight.bold,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Subtitle Text
                  const Text(
                    'Track waste collection\nwith optimized routes\nand smart bins.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      height: 1.35,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(flex: 3),

                  // Bottom Navigation Bar (Page Dots + Next Button)
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      // Centered Dots Indicator
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(_totalPages, (index) {
                          final isActive = index == _currentPage;
                          return AnimatedContainer(
                            duration: const Duration(milliseconds: 250),
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            width: isActive ? 10 : 8,
                            height: isActive ? 10 : 8,
                            decoration: BoxDecoration(
                              color: isActive
                                  ? Colors.white
                                  : Colors.white.withOpacity(0.4),
                              shape: BoxShape.circle,
                            ),
                          );
                        }),
                      ),

                      // Bottom Right "Next >" Button
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: () {},
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: 8.0,
                              horizontal: 4.0,
                            ),
                            child: Text(
                              'Next >',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
