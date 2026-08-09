import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Screen/Auth/AuthSelectionScreen.dart';
import 'package:greentech/Screen/Auth/LoginScreen.dart';
import 'package:greentech/Screen/Auth/SignupScreen.dart';
import 'package:greentech/Screen/Chat/ChatScreen.dart';
import 'package:greentech/Screen/Marketplace/ListingsScreen.dart';
import 'package:greentech/Screen/NotFound/NotFoundScreen.dart';
import 'package:greentech/Screen/Notifications/NotificationsScreen.dart';
import 'package:greentech/Screen/Pickup/PickupDetailScreen.dart';
import 'package:greentech/Screen/Home/ImageScreen.dart';
import 'package:greentech/Screen/Home/PickupScreen.dart';
import 'package:greentech/Screen/Recycler/NearbyYardsScreen.dart';
import 'package:greentech/Screen/Rewards/LeaderboardScreen.dart';
import 'package:greentech/Screen/Rewards/RewardsScreen.dart';
import 'package:greentech/Screen/Wallet/WalletScreen.dart';
import 'package:greentech/Screen/Profile/ProfileScreen.dart';
import 'package:greentech/Screen/Splash/SplashScreen.dart';

// Import your BottomNavBar
import 'package:greentech/Widget/BottomNavBar.dart';

const _authRoutes = {'/auth', '/login', '/signup'};

const _publicRoutes = {'/', '/auth', '/login', '/signup'};

const _rewardRoutes = {'/rewards', '/leaderboard'};

const _pickupRoutes = {'/pickup', '/my-pickups'};

const _sellRoutes = {'/listings'};

class _SessionRefresh extends ChangeNotifier {
  _SessionRefresh(Ref ref) {
    ref.listen(sessionProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refresh = _SessionRefresh(ref);
  ref.onDispose(refresh.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,

    redirect: (context, state) {
      final session = ref.read(sessionProvider);
      if (session.isLoading) return null;

      final location = state.matchedLocation;
      if (location == '/') return null;

      final signedIn = session.value != null;

      if (signedIn && _authRoutes.contains(location)) return '/home';

      if (!signedIn && !_publicRoutes.contains(location)) return '/auth';

      final role = session.value?.role;

      if (role != null) {
        if (!role.earnsRewards && _rewardRoutes.contains(location)) {
          return '/home';
        }
        if (!role.canRequestPickup && _pickupRoutes.contains(location)) {
          return '/home';
        }
        if (!role.canSellScrap && _sellRoutes.contains(location)) {
          return '/home';
        }
      }

      return null;
    },

    errorBuilder: (context, state) => const NotFoundScreen(),

    routes: [
      GoRoute(
        path: '/',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      GoRoute(
        path: '/home',
        name: 'home',
        builder: (context, state) => const BottomNavBar(initialIndex: 0),
      ),
      GoRoute(
        path: '/image',
        name: 'image',
        builder: (context, state) => const BottomNavBar(initialIndex: 1),
      ),
      GoRoute(
        path: '/pickup',
        name: 'pickup',
        builder: (context, state) => const BottomNavBar(initialIndex: 2),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const BottomNavBar(initialIndex: 3),
      ),
      GoRoute(
        path: '/profile',
        name: 'profile',
        builder: (context, state) => const ProfileScreen(),
      ),
      GoRoute(
        path: '/yards',
        name: 'yards',
        builder: (context, state) => const NearbyYardsScreen(),
      ),
      GoRoute(
        path: '/scan',
        name: 'scan',
        builder: (context, state) => const ImageScreen(standalone: true),
      ),
      GoRoute(
        path: '/my-pickups',
        name: 'myPickups',
        builder: (context, state) => const PickupScreen(standalone: true),
      ),
      GoRoute(
        path: '/leaderboard',
        name: 'leaderboard',
        builder: (context, state) => const LeaderboardScreen(),
      ),
      GoRoute(
        path: '/rewards',
        name: 'rewards',
        builder: (context, state) => const RewardsScreen(),
      ),
      GoRoute(
        path: '/wallet',
        name: 'wallet',
        builder: (context, state) => const WalletScreen(),
      ),
      GoRoute(
        path: '/chat',
        name: 'chat',
        builder: (context, state) => const ChatScreen(),
      ),
      GoRoute(
        path: '/listings',
        name: 'listings',
        builder: (context, state) => const ListingsScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/pickups/:id',
        name: 'pickupDetail',
        builder: (context, state) =>
            PickupDetailScreen(pickupId: state.pathParameters['id'] ?? ''),
      ),
    ],
  );
});
