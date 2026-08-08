class MapConfig {
  const MapConfig._();

  static const String accessToken =
      String.fromEnvironment('MAPBOX_ACCESS_TOKEN');

  static const String styleId = 'mapbox/streets-v12';

  static const String userAgentPackageName = 'com.example.greentech';

  static bool get isEnabled => accessToken.isNotEmpty;

  static String get tileUrl =>
      'https://api.mapbox.com/styles/v1/$styleId/tiles/512/{z}/{x}/{y}@2x'
      '?access_token=$accessToken';

  static const double minZoom = 4;

  static const double maxZoom = 18;

  static const double fallbackLat = 22.5892;

  static const double fallbackLon = 88.3103;
}
