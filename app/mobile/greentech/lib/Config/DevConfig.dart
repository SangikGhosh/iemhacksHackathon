import 'package:flutter/foundation.dart';

import 'package:greentech/Model/AppUser.dart';

class DevConfig {
  const DevConfig._();

  static const bool _bypassRequested = true;

  static const Role _role = Role.citizen;

  static bool get bypassAuth => kDebugMode && _bypassRequested;

  static AppUser get user => const AppUser(
    id: 'dev-local-user',
    email: 'dev@greenroute.local',
    fullName: 'Dev Preview',
    role: _role,
    points: 0,
  );
}
