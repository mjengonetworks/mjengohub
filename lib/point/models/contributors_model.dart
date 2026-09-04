// lib/point/models/contributors_model.dart
//
// Shapes for `GET /contributors` (api.py wraps application.py's
// get_community_leaderboards() verbatim) — Top Point Gainers and Top
// Project Contributors, each split into Profiles (users) and Pages
// (companies/orgs). Pages always come back empty today: the schema has no
// points/submission mechanism for Page entities yet — a real backend
// limitation, not a bug to work around client-side.

/// One ranked row — a user with their leaderboard value for the current
/// metric/window.
class LeaderboardRow {
  final int id;
  final String name;
  final String? avatar;
  final int value;

  const LeaderboardRow({required this.id, required this.name, this.avatar, required this.value});

  factory LeaderboardRow.fromJson(Map<String, dynamic> j) => LeaderboardRow(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? 'User',
        avatar: j['avatar'] as String?,
        value: (j['value'] as num?)?.toInt() ?? 0,
      );
}

/// One metric's Profiles/Pages split.
class LeaderboardMetric {
  final List<LeaderboardRow> profiles;
  final List<LeaderboardRow> pages;

  const LeaderboardMetric({this.profiles = const [], this.pages = const []});

  factory LeaderboardMetric.fromJson(Map<String, dynamic>? j) => LeaderboardMetric(
        profiles: (j?['profiles'] as List?)?.whereType<Map<String, dynamic>>().map(LeaderboardRow.fromJson).toList() ?? [],
        pages: (j?['pages'] as List?)?.whereType<Map<String, dynamic>>().map(LeaderboardRow.fromJson).toList() ?? [],
      );

  static const empty = LeaderboardMetric();
}

/// Both metrics for one timeframe window.
class CommunityLeaderboards {
  final LeaderboardMetric points;
  final LeaderboardMetric projects;

  const CommunityLeaderboards({this.points = LeaderboardMetric.empty, this.projects = LeaderboardMetric.empty});

  factory CommunityLeaderboards.fromJson(Map<String, dynamic> j) => CommunityLeaderboards(
        points: LeaderboardMetric.fromJson(j['points'] as Map<String, dynamic>?),
        projects: LeaderboardMetric.fromJson(j['projects'] as Map<String, dynamic>?),
      );

  static const empty = CommunityLeaderboards();
}

/// Timeframe filter shared by the Contributors screen and every embedded
/// preview widget.
enum LeaderboardWindow { past7Days, monthly, allTime }

extension LeaderboardWindowX on LeaderboardWindow {
  String get apiValue => switch (this) {
        LeaderboardWindow.past7Days => '7d',
        LeaderboardWindow.monthly => '30d',
        LeaderboardWindow.allTime => 'all',
      };

  String get label => switch (this) {
        LeaderboardWindow.past7Days => 'Past 7 Days',
        LeaderboardWindow.monthly => 'Monthly',
        LeaderboardWindow.allTime => 'All-Time',
      };
}
