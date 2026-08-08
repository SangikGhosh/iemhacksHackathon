import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:greentech/Config/DevConfig.dart';
import 'package:greentech/Model/AppUser.dart';
import 'package:greentech/Service/ApiService.dart';
import 'package:greentech/Service/UserService.dart';

class SessionController extends AsyncNotifier<AppUser?> {
  @override
  Future<AppUser?> build() async {
    if (await UserService.getToken() == null) {
      return DevConfig.bypassAuth ? DevConfig.user : null;
    }

    final cached = await UserService.getUserDetails();

    try {
      final user = await ApiService.me();
      await UserService.saveUserDetails(user);
      return user;
    } on ApiException catch (error) {
      if (error.isUnauthorized || error.statusCode == 404) {
        await UserService.clear();
        return null;
      }
      return cached;
    }
  }

  Future<void> adopt(AuthSession session) async {
    await UserService.saveSession(session);
    state = AsyncData(session.user);
  }

  Future<void> refresh() async {
    if (await UserService.getToken() == null) return;

    try {
      final user = await ApiService.me();
      await UserService.saveUserDetails(user);
      state = AsyncData(user);
    } on ApiException catch (error) {
      if (error.isUnauthorized || error.statusCode == 404) await signOut();
    }
  }

  Future<void> signOut() async {
    await UserService.clear();
    state = const AsyncData(null);
  }
}

final sessionProvider = AsyncNotifierProvider<SessionController, AppUser?>(
  SessionController.new,
);
