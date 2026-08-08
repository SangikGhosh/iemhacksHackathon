enum Role {
  citizen(
    'CITIZEN',
    'Citizen',
    'Log household waste, earn points for correct segregation.',
  ),
  collector(
    'COLLECTOR',
    'Collector',
    'Run pickup routes and confirm collections on the ground.',
  ),
  recycler(
    'RECYCLER',
    'Recycler',
    'Receive sorted material and record what gets processed.',
  ),
  municipalAdmin('MUNICIPAL_ADMIN', 'Municipal admin', ''),
  superAdmin('SUPER_ADMIN', 'Super admin', '');

  const Role(this.wire, this.label, this.blurb);

  final String wire;

  final String label;

  final String blurb;

  static const List<Role> selectable = [citizen, collector, recycler];

  static Role fromWire(String? value) =>
      values.firstWhere((role) => role.wire == value, orElse: () => citizen);
}

class AppUser {
  const AppUser({
    required this.id,
    required this.email,
    required this.fullName,
    required this.role,
    required this.points,
  });

  final String id;
  final String email;
  final String fullName;
  final Role role;
  final int points;

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id']?.toString() ?? '',
    email: json['email']?.toString() ?? '',
    fullName: json['fullName']?.toString() ?? '',
    role: Role.fromWire(json['role']?.toString()),
    points: (json['points'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'email': email,
    'fullName': fullName,
    'role': role.wire,
    'points': points,
  };

  String get firstName {
    final trimmed = fullName.trim();
    if (trimmed.isNotEmpty) return trimmed.split(RegExp(r'\s+')).first;
    return email.split('@').first;
  }

  String get initials {
    final parts = fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return email.isNotEmpty ? email[0].toUpperCase() : '?';
    }
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }
}

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String tokenType;

  final int expiresIn;
  final AppUser user;

  factory AuthSession.fromJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['accessToken']?.toString() ?? '',
    tokenType: json['tokenType']?.toString() ?? 'Bearer',
    expiresIn: (json['expiresIn'] as num?)?.toInt() ?? 0,
    user: AppUser.fromJson(
      (json['user'] as Map?)?.cast<String, dynamic>() ?? const {},
    ),
  );
}
