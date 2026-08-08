import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:greentech/Screen/Home/HomeScreen.dart';
import 'package:greentech/Screen/Home/ImageScreen.dart';
import 'package:greentech/Screen/Home/PickupScreen.dart';
import 'package:greentech/Screen/Home/SettingScreen.dart';
import 'package:hugeicons/hugeicons.dart';

class BottomNavBar extends StatefulWidget {
  final int initialIndex;

  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar> {
  late int currentIndex;
  late PageController _pageController;

  final List<Widget> pages = [
    const HomeScreen(key: ValueKey('HomeScreen')),
    const ImageScreen(key: ValueKey('ImageScreen')),
    const PickupScreen(key: ValueKey('PickupScreen')),
    const SettingScreen(key: ValueKey('SettingScreen')),
  ];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == currentIndex) return;

    HapticFeedback.lightImpact();

    setState(() {
      currentIndex = index;
    });
    _pageController.jumpToPage(index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 15,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: SafeArea(
          child: Container(
            height: 75,
            padding: const EdgeInsets.only(top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildNavItem(0, HugeIcons.strokeRoundedHome11, "Home"),
                _buildNavItem(1, HugeIcons.strokeRoundedImage01, "Image"),
                _buildNavItem(
                  2,
                  HugeIcons.strokeRoundedDeliveryBox01,
                  "Pickup",
                ),
                _buildNavItem(3, HugeIcons.strokeRoundedSettings01, "Settings"),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, dynamic iconData, String label) {
    final bool isActive = currentIndex == index;

    return GestureDetector(
      onTap: () => _onItemTapped(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 70,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              width: 36,
              height: 36,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? Colors.black : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: HugeIcon(
                icon: iconData,
                size: 22,
                color: isActive ? Colors.white : Colors.black45,
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? Colors.black : Colors.black45,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}
