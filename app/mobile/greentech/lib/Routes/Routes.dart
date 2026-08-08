import 'package:go_router/go_router.dart';

import '../Features/NotFound/Screen/NotFoundScreen.dart';
import '../Features/Splash/Screen/SplashScreen.dart';
import '../Screen/Auth/AuthSelectionScreen.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/',

  errorBuilder: (context, state) {
    return const NotFoundScreen();
  },

  routes: [
    GoRoute(
      path: '/',
      name: 'splash',
      builder: (context, state) {
        return const SplashScreen();
      },
    ),
    GoRoute(
      path: '/auth',
      name: 'auth',
      builder: (context, state) {
        return const AuthSelectionScreen();
      },
    ),
  ],
);
