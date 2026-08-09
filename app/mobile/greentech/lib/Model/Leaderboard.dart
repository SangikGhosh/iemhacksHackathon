class LeaderboardEntry {
  const LeaderboardEntry({
    required this.rank,
    required this.userId,
    required this.fullName,
    required this.role,
    required this.points,
    required this.completedPickups,
    required this.totalWeightKg,
  });

  final int rank;
  final String userId;
  final String fullName;
  final String role;
  final int points;
  final int completedPickups;
  final double totalWeightKg;

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) =>
      LeaderboardEntry(
        rank: (json['rank'] as num?)?.toInt() ?? 0,
        userId: json['userId']?.toString() ?? '',
        fullName: json['fullName']?.toString() ?? 'Someone',
        role: json['role']?.toString() ?? 'CITIZEN',
        points: (json['points'] as num?)?.toInt() ?? 0,
        completedPickups: (json['completedPickups'] as num?)?.toInt() ?? 0,
        totalWeightKg: (json['totalWeightKg'] as num?)?.toDouble() ?? 0,
      );
}

class LeaderboardMe {
  const LeaderboardMe({
    required this.rank,
    required this.points,
    required this.completedPickups,
    required this.ahead,
  });

  final int rank;
  final int points;
  final int completedPickups;
  final int ahead;

  factory LeaderboardMe.fromJson(Map<String, dynamic> json) => LeaderboardMe(
    rank: (json['rank'] as num?)?.toInt() ?? 0,
    points: (json['points'] as num?)?.toInt() ?? 0,
    completedPickups: (json['completedPickups'] as num?)?.toInt() ?? 0,
    ahead: (json['ahead'] as num?)?.toInt() ?? 0,
  );
}

class LeaderboardTotals {
  const LeaderboardTotals({
    required this.citizens,
    required this.points,
    required this.weightKg,
    required this.completedPickups,
  });

  final int citizens;
  final int points;
  final double weightKg;
  final int completedPickups;

  factory LeaderboardTotals.fromJson(Map<String, dynamic> json) =>
      LeaderboardTotals(
        citizens: (json['citizens'] as num?)?.toInt() ?? 0,
        points: (json['points'] as num?)?.toInt() ?? 0,
        weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
        completedPickups: (json['completedPickups'] as num?)?.toInt() ?? 0,
      );
}

class Leaderboard {
  const Leaderboard({
    required this.scope,
    required this.entries,
    required this.me,
    required this.totals,
  });

  final String scope;
  final List<LeaderboardEntry> entries;
  final LeaderboardMe? me;
  final LeaderboardTotals totals;

  bool get meIsVisible =>
      me != null && entries.any((entry) => entry.rank == me!.rank);

  factory Leaderboard.fromJson(Map<String, dynamic> json) {
    final me = (json['me'] as Map?)?.cast<String, dynamic>();
    return Leaderboard(
      scope: json['scope']?.toString() ?? 'ALL_TIME',
      entries:
          (json['entries'] as List?)
              ?.whereType<Map>()
              .map(
                (item) =>
                    LeaderboardEntry.fromJson(item.cast<String, dynamic>()),
              )
              .toList() ??
          const [],
      me: me == null ? null : LeaderboardMe.fromJson(me),
      totals: LeaderboardTotals.fromJson(
        (json['totals'] as Map?)?.cast<String, dynamic>() ?? const {},
      ),
    );
  }
}
