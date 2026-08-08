import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:greentech/Provider/SessionProvider.dart';
import 'package:greentech/Screen/Auth/AuthSelectionScreen.dart';
import 'package:greentech/Screen/Auth/LoginScreen.dart';
import 'package:greentech/Screen/Auth/SignupScreen.dart';
import 'package:greentech/Screen/NotFound/NotFoundScreen.dart';
import 'package:greentech/Screen/Splash/SplashScreen.dart';

// Import your BottomNavBar
import 'package:greentech/Widget/BottomNavBar.dart';

const _authRoutes = {'/auth', '/login', '/signup'};

const _protectedRoutes = {'/home', '/image', '/pickup', '/settings'};

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
      final location = state.matchedLocation;

      if (location == '/' || session.isLoading) return null;

      final signedIn = session.value != null;

      if (signedIn && _authRoutes.contains(location)) return '/home';
      
      if (!signedIn && _protectedRoutes.contains(location)) return '/auth';
      
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
    ],
  );
});