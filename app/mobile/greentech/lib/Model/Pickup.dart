enum PickupStatus {
  requested('REQUESTED', 'Looking for a collector'),
  accepted('ACCEPTED', 'Collector on the way'),
  completed('COMPLETED', 'Collected'),
  cancelled('CANCELLED', 'Cancelled'),
  unknown('', 'Pickup');

  const PickupStatus(this.wire, this.label);

  final String wire;

  final String label;

  bool get isOpen => this == requested || this == accepted;

  static PickupStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == (value ?? '').toUpperCase(),
    orElse: () => PickupStatus.unknown,
  );
}

enum PickupMode {
  doorstep('DOORSTEP', 'Doorstep', 5),
  dropOff('DROP_OFF', 'Drop-off', 8),
  unknown('', 'Pickup', 0);

  const PickupMode(this.wire, this.label, this.pointsPerKg);

  final String wire;

  final String label;

  final int pointsPerKg;

  static PickupMode fromWire(String? value) => values.firstWhere(
    (mode) => mode.wire == (value ?? '').toUpperCase(),
    orElse: () => PickupMode.unknown,
  );
}

class Party {
  const Party({required this.id, required this.fullName, required this.email});

  final String id;
  final String fullName;
  final String email;

  factory Party.fromJson(Map<String, dynamic> json) => Party(
    id: json['id']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
  );
}

class PickupMoney {
  const PickupMoney({
    required this.currency,
    required this.estimatedOffer,
    required this.finalAmount,
    required this.finalWeightKg,
  });

  final String currency;
  final double estimatedOffer;
  final double? finalAmount;
  final double? finalWeightKg;

  bool get isSettled => finalAmount != null;

  double get payable => finalAmount ?? estimatedOffer;

  factory PickupMoney.fromJson(Map<String, dynamic> json) => PickupMoney(
    currency: json['currency']?.toString() ?? 'INR',
    estimatedOffer: (json['estimatedOffer'] as num?)?.toDouble() ?? 0,
    finalAmount: (json['finalAmount'] as num?)?.toDouble(),
    finalWeightKg: (json['finalWeightKg'] as num?)?.toDouble(),
  );
}

class PickupLocation {
  const PickupLocation({
    required this.address,
    required this.landmark,
    required this.latitude,
    required this.longitude,
  });

  final String address;
  final String? landmark;
  final double? latitude;
  final double? longitude;

  bool get hasCoordinates => latitude != null && longitude != null;

  factory PickupLocation.fromJson(Map<String, dynamic> json) => PickupLocation(
    address: json['address']?.toString() ?? '',
    landmark: json['landmark']?.toString(),
    latitude: (json['latitude'] as num?)?.toDouble(),
    longitude: (json['longitude'] as num?)?.toDouble(),
  );
}

class Pickup {
  const Pickup({
    required this.id,
    required this.detectionId,
    required this.status,
    required this.mode,
    required this.collectionPointId,
    required this.rewardPoints,
    required this.rewardAwarded,
    required this.cancellable,
    required this.location,
    required this.contactPhone,
    required this.notes,
    required this.totalObjects,
    required this.materials,
    required this.money,
    required this.collector,
    required this.citizen,
    required this.cancelReason,
    required this.cancelledBy,
    required this.collectorNotes,
    required this.createdAt,
    required this.acceptedAt,
    required this.completedAt,
    required this.cancelledAt,
  });

  final String id;
  final String detectionId;
  final PickupStatus status;
  final PickupMode mode;
  final String? collectionPointId;
  final int rewardPoints;
  final bool rewardAwarded;
  final bool cancellable;
  final PickupLocation location;
  final String contactPhone;
  final String? notes;
  final int totalObjects;
  final String materials;
  final PickupMoney money;
  final Party? collector;
  final Party? citizen;
  final String? cancelReason;
  final String? cancelledBy;
  final String? collectorNotes;
  final DateTime? createdAt;
  final DateTime? acceptedAt;
  final DateTime? completedAt;
  final DateTime? cancelledAt;

  bool get hasCollector => collector != null;

  String get shortId =>
      id.length >= 8 ? id.substring(0, 8).toUpperCase() : id.toUpperCase();

  factory Pickup.fromJson(Map<String, dynamic> json) {
    final contact =
        (json['contact'] as Map?)?.cast<String, dynamic>() ?? const {};
    final waste = (json['waste'] as Map?)?.cast<String, dynamic>() ?? const {};
    final collector = (json['collector'] as Map?)?.cast<String, dynamic>();
    final citizen = (json['citizen'] as Map?)?.cast<String, dynamic>();

    return Pickup(
      id: json['id']?.toString() ?? '',
      detectionId: json['detectionId']?.toString() ?? '',
      status: PickupStatus.fromWire(json['status']?.toString()),
      mode: PickupMode.fromWire(json['mode']?.toString()),
      collectionPointId: json['collectionPointId']?.toString(),
      rewardPoints: (json['rewardPoints'] as num?)?.toInt() ?? 0,
      rewardAwarded: json['rewardAwarded'] == true,
      cancellable: json['cancellable'] == true,
      location: PickupLocation.fromJson(
        (json['location'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      contactPhone: contact['phone']?.toString() ?? '',
      notes: contact['notes']?.toString(),
      totalObjects: (waste['totalObjects'] as num?)?.toInt() ?? 0,
      materials: waste['materials']?.toString() ?? '',
      money: PickupMoney.fromJson(
        (json['money'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
      collector: collector == null ? null : Party.fromJson(collector),
      citizen: citizen == null ? null : Party.fromJson(citizen),
      cancelReason: json['cancelReason']?.toString(),
      cancelledBy: json['cancelledBy']?.toString(),
      collectorNotes: json['collectorNotes']?.toString(),
      createdAt: _date(json['createdAt']),
      acceptedAt: _date(json['acceptedAt']),
      completedAt: _date(json['completedAt']),
      cancelledAt: _date(json['cancelledAt']),
    );
  }
}

class PickupPage {
  const PickupPage({
    required this.items,
    required this.page,
    required this.totalItems,
    required this.hasMore,
  });

  final List<Pickup> items;
  final int page;
  final int totalItems;
  final bool hasMore;

  factory PickupPage.fromJson(Map<String, dynamic> json) => PickupPage(
    items:
        (json['items'] as List?)
            ?.whereType<Map>()
            .map((item) => Pickup.fromJson(item.cast<String, dynamic>()))
            .toList() ??
        const [],
    page: (json['page'] as num?)?.toInt() ?? 0,
    totalItems: (json['totalItems'] as num?)?.toInt() ?? 0,
    hasMore: json['hasMore'] == true,
  );
}

DateTime? _date(Object? value) {
  final text = value?.toString();
  if (text == null || text.isEmpty) return null;
  return DateTime.tryParse(text)?.toLocal();
}
