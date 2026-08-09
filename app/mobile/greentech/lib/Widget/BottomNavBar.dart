import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Provider/CitizenProviders.dart';
import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Screen/Collector/JobsScreen.dart';
import 'package:greentech/Screen/Collector/MyWorkScreen.dart';
import 'package:greentech/Screen/Collector/RouteScreen.dart';
import 'package:greentech/Screen/Recycler/MarketScreen.dart';
import 'package:greentech/Screen/Recycler/PurchasesScreen.dart';
import 'package:greentech/Screen/Wallet/WalletScreen.dart';
import 'package:greentech/Screen/Home/HomeScreen.dart';
import 'package:greentech/Screen/Home/ImageScreen.dart';
import 'package:greentech/Screen/Home/PickupScreen.dart';
import 'package:greentech/Screen/Home/SettingScreen.dart';
import 'package:hugeicons/hugeicons.dart';

class NavTab {
  const NavTab({required this.icon, required this.label, required this.page});

  final dynamic icon;
  final String label;
  final Widget page;
}

List<NavTab> tabsForRole(Role role) {
  if (role == Role.collector) {
    return [
      const NavTab(
        icon: HugeIcons.strokeRoundedDeliveryBox01,
        label: 'Jobs',
        page: JobsScreen(key: ValueKey('JobsScreen')),
      ),
      const NavTab(
        icon: HugeIcons.strokeRoundedRoute01,
        label: 'Route',
        page: RouteScreen(key: ValueKey('RouteScreen')),
      ),
      const NavTab(
        icon: HugeIcons.strokeRoundedTruck,
        label: 'My work',
        page: MyWorkScreen(key: ValueKey('MyWorkScreen')),
      ),
      const NavTab(
        icon: HugeIcons.strokeRoundedSettings01,
        label: 'Settings',
        page: SettingScreen(key: ValueKey('SettingScreen')),
      ),
    ];
  }

  if (role == Role.recycler) {
    return [
      const NavTab(
        icon: HugeIcons.strokeRoundedShoppingBag01,
        label: 'Market',
        page: MarketScreen(key: ValueKey('MarketScreen')),
      ),
      const NavTab(
        icon: HugeIcons.strokeRoundedPackage,
        label: 'Purchases',
        page: PurchasesScreen(key: ValueKey('PurchasesScreen')),
      ),
      const NavTab(
        icon: HugeIcons.strokeRoundedWallet01,
        label: 'Wallet',
        page: WalletScreen(key: ValueKey('WalletScreen'), embedded: true),
      ),
      const NavTab(
        icon: HugeIcons.strokeRoundedSettings01,
        label: 'Settings',
        page: SettingScreen(key: ValueKey('SettingScreen')),
      ),
    ];
  }

  return [
    const NavTab(
      icon: HugeIcons.strokeRoundedHome11,
      label: 'Home',
      page: HomeScreen(key: ValueKey('HomeScreen')),
    ),
    const NavTab(
      icon: HugeIcons.strokeRoundedImage01,
      label: 'Image',
      page: ImageScreen(key: ValueKey('ImageScreen')),
    ),
    const NavTab(
      icon: HugeIcons.strokeRoundedDeliveryBox01,
      label: 'Pickup',
      page: PickupScreen(key: ValueKey('PickupScreen')),
    ),
    const NavTab(
      icon: HugeIcons.strokeRoundedSettings01,
      label: 'Settings',
      page: SettingScreen(key: ValueKey('SettingScreen')),
    ),
  ];
}

class BottomNavBar extends ConsumerStatefulWidget {
  final int initialIndex;

  const BottomNavBar({super.key, this.initialIndex = 0});

  @override
  ConsumerState<BottomNavBar> createState() => _BottomNavBarState();
}

class _BottomNavBarState extends ConsumerState<BottomNavBar>
    with WidgetsBindingObserver {
  late int currentIndex;
  late PageController _pageController;
  bool _watching = false;

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: currentIndex);
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWatcher());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _watching) {
      ref.read(notificationsProvider.notifier).syncFromServer();
    }
  }

  void _syncWatcher() {
    if (!mounted) return;

    final shouldWatch = ref.read(sessionProvider).value != null;

    if (shouldWatch && !_watching) {
      _watching = true;
      ref.read(notificationsProvider.notifier).start();
    } else if (!shouldWatch && _watching) {
      _watching = false;
      ref.read(notificationsProvider.notifier).stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
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
    final role = ref.watch(sessionProvider).value?.role ?? Role.citizen;
    final tabs = tabsForRole(role);
    WidgetsBinding.instance.addPostFrameCallback((_) => _syncWatcher());

    return Scaffold(
      backgroundColor: Colors.white,
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [for (final tab in tabs) tab.page],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
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
                for (var index = 0; index < tabs.length; index++)
                  _buildNavItem(index, tabs[index].icon, tabs[index].label),
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
