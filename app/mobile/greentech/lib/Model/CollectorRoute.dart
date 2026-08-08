import 'package:latlong2/latlong.dart';

import 'package:greentech/Utils/polyline.dart';

enum RouteStopType {
  dropOffPoint('DROP_OFF_POINT', 'Drop-off point'),
  doorstep('DOORSTEP', 'Doorstep'),
  unknown('', 'Stop');

  const RouteStopType(this.wire, this.label);

  final String wire;

  final String label;

  static RouteStopType fromWire(String? value) => values.firstWhere(
    (type) => type.wire == (value ?? '').toUpperCase(),
    orElse: () => RouteStopType.unknown,
  );
}

class RouteDepot {
  const RouteDepot({
    required this.municipalityCode,
    required this.name,
    required this.lat,
    required this.lon,
  });

  final String municipalityCode;
  final String name;
  final double lat;
  final double lon;

  LatLng get position => LatLng(lat, lon);

  factory RouteDepot.fromJson(Map<String, dynamic> json) => RouteDepot(
    municipalityCode: json['municipalityCode']?.toString() ?? '',
    name: json['name']?.toString() ?? 'Depot',
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lon: (json['lon'] as num?)?.toDouble() ?? 0,
  );
}

class RouteStop {
  const RouteStop({
    required this.sequence,
    required this.type,
    required this.collectionPointId,
    required this.pickupIds,
    required this.address,
    required this.lat,
    required this.lon,
    required this.pickupCount,
    required this.weightKg,
  });

  final int sequence;
  final RouteStopType type;
  final String? collectionPointId;
  final List<String> pickupIds;
  final String address;
  final double lat;
  final double lon;
  final int pickupCount;
  final double weightKg;

  LatLng get position => LatLng(lat, lon);

  factory RouteStop.fromJson(Map<String, dynamic> json) => RouteStop(
    sequence: (json['sequence'] as num?)?.toInt() ?? 0,
    type: RouteStopType.fromWire(json['type']?.toString()),
    collectionPointId: json['collectionPointId']?.toString(),
    pickupIds:
        (json['pickupIds'] as List?)?.map((id) => id.toString()).toList() ??
        const [],
    address: json['address']?.toString() ?? '',
    lat: (json['lat'] as num?)?.toDouble() ?? 0,
    lon: (json['lon'] as num?)?.toDouble() ?? 0,
    pickupCount: (json['pickupCount'] as num?)?.toInt() ?? 0,
    weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
  );
}

class CollectorRoute {
  const CollectorRoute({
    required this.depot,
    required this.stops,
    required this.totalRequests,
    required this.totalStops,
    required this.plannedLoadKg,
    required this.vehicleCapacityKg,
    required this.deferredPickupIds,
    required this.distanceKm,
    required this.durationMinutes,
    required this.geometry,
  });

  final RouteDepot depot;
  final List<RouteStop> stops;
  final int totalRequests;
  final int totalStops;
  final double plannedLoadKg;
  final double vehicleCapacityKg;
  final List<String> deferredPickupIds;
  final double? distanceKm;
  final double? durationMinutes;
  final String? geometry;

  bool get hasDeferred => deferredPickupIds.isNotEmpty;

  double get loadPercent => vehicleCapacityKg <= 0
      ? 0
      : (plannedLoadKg / vehicleCapacityKg).clamp(0.0, 1.0);

  List<LatLng> get line {
    final decoded = decodePolyline(geometry ?? '');
    if (decoded.isNotEmpty) return decoded;

    return [
      depot.position,
      ...stops.map((stop) => stop.position),
      depot.position,
    ];
  }

  bool get isStraightLineFallback => (geometry ?? '').isEmpty;

  List<LatLng> get allPoints => [
    depot.position,
    ...stops.map((stop) => stop.position),
  ];

  factory CollectorRoute.fromJson(Map<String, dynamic> json) => CollectorRoute(
    depot: RouteDepot.fromJson(
      (json['depot'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
    stops:
        (json['stops'] as List?)
            ?.whereType<Map>()
            .map((stop) => RouteStop.fromJson(stop.cast<String, dynamic>()))
            .toList() ??
        const [],
    totalRequests: (json['totalRequests'] as num?)?.toInt() ?? 0,
    totalStops: (json['totalStops'] as num?)?.toInt() ?? 0,
    plannedLoadKg: (json['plannedLoadKg'] as num?)?.toDouble() ?? 0,
    vehicleCapacityKg: (json['vehicleCapacityKg'] as num?)?.toDouble() ?? 0,
    deferredPickupIds:
        (json['deferredPickupIds'] as List?)
            ?.map((id) => id.toString())
            .toList() ??
        const [],
    distanceKm: (json['distanceKm'] as num?)?.toDouble(),
    durationMinutes: (json['durationMinutes'] as num?)?.toDouble(),
    geometry: json['geometry']?.toString(),
  );
}
