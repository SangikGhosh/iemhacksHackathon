import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greentech/Routes/Routes.dart';

const Color appBackground = Color(0xFFF5F1EE);
const Color appInk = Color(0xFF141414);

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: ref.watch(routerProvider),

      theme: ThemeData(
        fontFamily: 'CodecPro',
        brightness: Brightness.light,
        scaffoldBackgroundColor: appBackground,
        colorScheme: ColorScheme.fromSeed(
          seedColor: appInk,
          surface: appBackground,
          primary: appInk,
          primaryContainer: const Color(0xFFEAE5E0),
          onSurface: appInk,
          onSurfaceVariant: const Color(0xFF5A544E),
          outline: const Color(0xFF938C84),
          outlineVariant: const Color(0xFFE3DDD6),
          surfaceContainerHighest: const Color(0xFFDBD4CC),
        ),
      ),
      builder: (context, child) {
        SystemChrome.setSystemUIOverlayStyle(
          const SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness: Brightness.dark,
            systemNavigationBarColor: appBackground,
            systemNavigationBarIconBrightness: Brightness.dark,
          ),
        );
        return child!;
      },
    );
  }
}
