import 'package:latlong2/latlong.dart';

enum CollectionPointType {
  mrf('MRF', 'Recovery facility'),
  binCluster('BIN_CLUSTER', 'Bin cluster'),
  scrapYard('SCRAP_YARD', 'Scrap yard'),
  compostHub('COMPOST_HUB', 'Compost hub'),
  unknown('', 'Collection point');

  const CollectionPointType(this.wire, this.label);

  final String wire;

  final String label;

  static CollectionPointType fromWire(String? value) => values.firstWhere(
    (type) => type.wire == (value ?? '').toUpperCase(),
    orElse: () => CollectionPointType.unknown,
  );
}

class CollectionPoint {
  const CollectionPoint({
    required this.id,
    required this.code,
    required this.name,
    required this.locality,
    required this.ward,
    required this.type,
    required this.lat,
    required this.lon,
    required this.municipality,
    required this.district,
    this.straightLineKm,
    this.roadDistanceKm,
    this.drivingMinutes,
  });

  final String id;
  final String code;
  final String name;
  final String locality;
  final String ward;
  final CollectionPointType type;
  final double lat;
  final double lon;
  final String municipality;
  final String district;
  final double? straightLineKm;
  final double? roadDistanceKm;
  final double? drivingMinutes;

  LatLng get position => LatLng(lat, lon);

  double? get bestDistanceKm => roadDistanceKm ?? straightLineKm;

  bool get hasRoadDistance => roadDistanceKm != null;

  String get subtitle {
    final parts = [
      if (locality.isNotEmpty) locality,
      if (ward.isNotEmpty) ward,
    ];
    return parts.isEmpty ? municipality : parts.join(' · ');
  }

  factory CollectionPoint.fromJson(Map<String, dynamic> json) =>
      CollectionPoint(
        id: json['id']?.toString() ?? '',
        code: json['code']?.toString() ?? '',
        name: json['name']?.toString() ?? 'Collection point',
        locality: json['locality']?.toString() ?? '',
        ward: json['ward']?.toString() ?? '',
        type: CollectionPointType.fromWire(json['type']?.toString()),
        lat: (json['lat'] as num?)?.toDouble() ?? 0,
        lon: (json['lon'] as num?)?.toDouble() ?? 0,
        municipality: json['municipality']?.toString() ?? '',
        district: json['district']?.toString() ?? '',
        straightLineKm: (json['straightLineKm'] as num?)?.toDouble(),
        roadDistanceKm: (json['roadDistanceKm'] as num?)?.toDouble(),
        drivingMinutes: (json['drivingMinutes'] as num?)?.toDouble(),
      );
}

class Municipality {
  const Municipality({
    required this.code,
    required this.name,
    required this.district,
    required this.state,
    required this.depotName,
    required this.depotLat,
    required this.depotLon,
  });

  final String code;
  final String name;
  final String district;
  final String state;
  final String depotName;
  final double depotLat;
  final double depotLon;

  LatLng get depotPosition => LatLng(depotLat, depotLon);

  factory Municipality.fromJson(Map<String, dynamic> json) {
    final depot = (json['depot'] as Map?)?.cast<String, dynamic>() ?? const {};
    return Municipality(
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      district: json['district']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      depotName: depot['name']?.toString() ?? 'Depot',
      depotLat: (depot['lat'] as num?)?.toDouble() ?? 0,
      depotLon: (depot['lon'] as num?)?.toDouble() ?? 0,
    );
  }
}
