enum DetectionStatus {
  ok('OK', 'Waste identified'),
  manualPricing('MANUAL_PRICING_REQUIRED', 'Collector sets the price'),
  noWaste('NO_WASTE_DETECTED', 'No waste found'),
  lowConfidence('LOW_CONFIDENCE', 'Not sure about this one'),
  unknown('UNKNOWN', 'Scan complete');

  const DetectionStatus(this.wire, this.headline);

  final String wire;

  final String headline;

  static DetectionStatus fromWire(String? value) => values.firstWhere(
    (status) => status.wire == value,
    orElse: () => DetectionStatus.unknown,
  );
}

enum WasteBin {
  blue('BLUE', 'Blue bin', 'Dry recyclables'),
  green('GREEN', 'Green bin', 'Wet and compostable'),
  red('RED', 'Red bin', 'Hazardous waste'),
  grey('GREY', 'Grey bin', 'Non-recyclable waste'),
  unknown('', 'Not assigned', '');

  const WasteBin(this.wire, this.label, this.blurb);

  final String wire;

  final String label;

  final String blurb;

  static WasteBin fromWire(String? value) => values.firstWhere(
    (bin) => bin.wire == (value ?? '').toUpperCase(),
    orElse: () => WasteBin.unknown,
  );
}

class DetectionMaterial {
  const DetectionMaterial({
    required this.material,
    required this.category,
    required this.stream,
    required this.bin,
    required this.recyclable,
    required this.count,
    required this.pricePerKg,
    required this.estimatedWeightKg,
    required this.estimatedValue,
    required this.rewardPoints,
    required this.carbonSavedKg,
  });

  final String material;
  final String category;
  final String stream;
  final WasteBin bin;
  final bool recyclable;
  final int count;
  final double pricePerKg;
  final double estimatedWeightKg;
  final double estimatedValue;
  final int rewardPoints;
  final double carbonSavedKg;

  factory DetectionMaterial.fromJson(Map<String, dynamic> json) =>
      DetectionMaterial(
        material: json['material']?.toString() ?? 'Unknown material',
        category: json['category']?.toString() ?? '',
        stream: json['stream']?.toString() ?? '',
        bin: WasteBin.fromWire(json['bin']?.toString()),
        recyclable: json['recyclable'] == true,
        count: _int(json['count']),
        pricePerKg: _double(json['pricePerKg']),
        estimatedWeightKg: _double(json['estimatedWeightKg']),
        estimatedValue: _double(json['estimatedValue']),
        rewardPoints: _int(json['rewardPoints']),
        carbonSavedKg: _double(json['carbonSavedKg']),
      );
}

class DetectionOffer {
  const DetectionOffer({
    required this.currency,
    required this.minimumOffer,
    required this.estimatedOffer,
    required this.maximumOffer,
    required this.status,
    required this.finalPriceSetBy,
  });

  final String currency;
  final double minimumOffer;
  final double estimatedOffer;
  final double maximumOffer;
  final String status;
  final String finalPriceSetBy;

  bool get hasValue => estimatedOffer > 0 || maximumOffer > 0;

  bool get awaitingCollector => status == 'PENDING_COLLECTOR_CONFIRMATION';

  bool get hasRange => maximumOffer > minimumOffer;

  double get spread => hasRange ? maximumOffer - minimumOffer : 0;

  double get position => hasRange
      ? ((estimatedOffer - minimumOffer) / spread).clamp(0.0, 1.0)
      : 0.5;

  factory DetectionOffer.fromJson(Map<String, dynamic> json) => DetectionOffer(
    currency: json['currency']?.toString() ?? 'INR',
    minimumOffer: _double(json['minimumOffer']),
    estimatedOffer: _double(json['estimatedOffer']),
    maximumOffer: _double(json['maximumOffer']),
    status: json['status']?.toString() ?? 'UNAVAILABLE',
    finalPriceSetBy: json['finalPriceSetBy']?.toString() ?? 'SYSTEM',
  );
}

class DetectionImpact {
  const DetectionImpact({
    required this.estimatedWeightKg,
    required this.carbonSavedKg,
    required this.landfillReducedKg,
    required this.recyclablePercent,
  });

  final double estimatedWeightKg;
  final double carbonSavedKg;
  final double landfillReducedKg;
  final int recyclablePercent;

  factory DetectionImpact.fromJson(Map<String, dynamic> json) =>
      DetectionImpact(
        estimatedWeightKg: _double(json['estimatedWeightKg']),
        carbonSavedKg: _double(json['carbonSavedKg']),
        landfillReducedKg: _double(json['landfillReducedKg']),
        recyclablePercent: _int(json['recyclablePercent']),
      );
}

class DetectionRecommendation {
  const DetectionRecommendation({
    required this.primaryBin,
    required this.secondaryBin,
    required this.pickupRecommended,
  });

  final WasteBin primaryBin;
  final WasteBin secondaryBin;
  final bool pickupRecommended;

  factory DetectionRecommendation.fromJson(Map<String, dynamic> json) =>
      DetectionRecommendation(
        primaryBin: WasteBin.fromWire(json['primaryBin']?.toString()),
        secondaryBin: WasteBin.fromWire(json['secondaryBin']?.toString()),
        pickupRecommended: json['pickupRecommended'] == true,
      );
}

class DetectionQuality {
  const DetectionQuality({
    required this.detectionQuality,
    required this.averageConfidence,
  });

  final String detectionQuality;
  final double averageConfidence;

  int get confidencePercent => (averageConfidence * 100).round();

  factory DetectionQuality.fromJson(Map<String, dynamic> json) =>
      DetectionQuality(
        detectionQuality: json['detectionQuality']?.toString() ?? 'NONE',
        averageConfidence: _double(json['averageConfidence']),
      );
}

class Detection {
  const Detection({
    required this.id,
    required this.eligible,
    required this.status,
    required this.message,
    required this.actionRequired,
    required this.imageUrl,
    required this.totalObjects,
    required this.totalRewardPoints,
    required this.pointsAwarded,
    required this.userPointsBalance,
    required this.offer,
    required this.impact,
    required this.recommendation,
    required this.quality,
    required this.aiSummary,
    required this.processingTimeMs,
    required this.materials,
  });

  final String id;
  final bool eligible;
  final DetectionStatus status;
  final String message;
  final String? actionRequired;
  final String? imageUrl;
  final int totalObjects;
  final int totalRewardPoints;
  final bool pointsAwarded;
  final int userPointsBalance;
  final DetectionOffer offer;
  final DetectionImpact impact;
  final DetectionRecommendation recommendation;
  final DetectionQuality quality;
  final String aiSummary;
  final int processingTimeMs;
  final List<DetectionMaterial> materials;

  bool get needsRetake => actionRequired == 'RECLICK_IMAGE';

  bool get needsCollectorPrice => actionRequired == 'COLLECTOR_SETS_PRICE';

  factory Detection.fromJson(Map<String, dynamic> json) => Detection(
    id: json['id']?.toString() ?? '',
    eligible: json['eligible'] == true,
    status: DetectionStatus.fromWire(json['status']?.toString()),
    message: json['message']?.toString() ?? '',
    actionRequired: json['actionRequired']?.toString(),
    imageUrl: json['imageUrl']?.toString(),
    totalObjects: _int(json['totalObjects']),
    totalRewardPoints: _int(json['totalRewardPoints']),
    pointsAwarded: json['pointsAwarded'] == true,
    userPointsBalance: _int(json['userPointsBalance']),
    offer: DetectionOffer.fromJson(_map(json['offer'])),
    impact: DetectionImpact.fromJson(_map(json['impact'])),
    recommendation: DetectionRecommendation.fromJson(
      _map(json['recommendation']),
    ),
    quality: DetectionQuality.fromJson(_map(json['quality'])),
    aiSummary: json['aiSummary']?.toString() ?? '',
    processingTimeMs: _int(json['processingTimeMs']),
    materials:
        (json['materials'] as List?)
            ?.whereType<Map>()
            .map((item) => DetectionMaterial.fromJson(item.cast()))
            .toList() ??
        const [],
  );
}

Map<String, dynamic> _map(Object? value) =>
    value is Map ? value.cast<String, dynamic>() : const {};

int _int(Object? value) => (value as num?)?.round() ?? 0;

double _double(Object? value) => (value as num?)?.toDouble() ?? 0;
