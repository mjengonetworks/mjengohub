// lib/point/models/points_models.dart
//
// Gamification/reputation logic ported from the website's `reputation.py`
// (get_points_level_info) so reviewer levels compute identically on both
// platforms. Levels are always derived live from `points` — there is no
// stored "reviewer_level" column on the backend User model.

/// The 10 "reviewer level" tiers (Google Local Guides-style), keyed by the
/// user's total `points`. Mirrors `POINTS_LEVELS` in the Flask app's
/// reputation.py exactly.
class ReviewerLevel {
  final int level;
  final String name;
  final int minPoints;
  final int? maxPoints; // null = no upper bound (top tier)

  const ReviewerLevel({
    required this.level,
    required this.name,
    required this.minPoints,
    this.maxPoints,
  });

  static const List<ReviewerLevel> _tiers = [
    ReviewerLevel(level: 1, name: 'Newcomer', minPoints: 0, maxPoints: 9),
    ReviewerLevel(level: 2, name: 'Contributor', minPoints: 10, maxPoints: 49),
    ReviewerLevel(level: 3, name: 'Contributor II', minPoints: 50, maxPoints: 149),
    ReviewerLevel(level: 4, name: 'Trusted Reviewer', minPoints: 150, maxPoints: 399),
    ReviewerLevel(level: 5, name: 'Trusted Reviewer II', minPoints: 400, maxPoints: 999),
    ReviewerLevel(level: 6, name: 'Expert', minPoints: 1000, maxPoints: 2499),
    ReviewerLevel(level: 7, name: 'Expert II', minPoints: 2500, maxPoints: 5999),
    ReviewerLevel(level: 8, name: 'Elite', minPoints: 6000, maxPoints: 14999),
    ReviewerLevel(level: 9, name: 'Elite II', minPoints: 15000, maxPoints: 39999),
    ReviewerLevel(level: 10, name: 'Legend', minPoints: 40000, maxPoints: null),
  ];

  static ReviewerLevel forPoints(int points) {
    for (final tier in _tiers.reversed) {
      if (points >= tier.minPoints) return tier;
    }
    return _tiers.first;
  }

  /// Progress (0.0-1.0) toward the next tier; 1.0 if already at the top tier.
  double progressToNext(int points) {
    if (maxPoints == null) return 1.0;
    final span = (maxPoints! + 1) - minPoints;
    final into = points - minPoints;
    return (into / span).clamp(0.0, 1.0);
  }

  int? get pointsToNext => maxPoints == null ? null : maxPoints! + 1;
}

/// One row from the website's `PointsLog` model.
class PointsLogEntry {
  final int id;
  final String source; // review | upvote | referral_signup | referral_prime
  final int points;
  final String? description;
  final DateTime? createdAt;

  const PointsLogEntry({
    required this.id,
    required this.source,
    required this.points,
    this.description,
    this.createdAt,
  });

  factory PointsLogEntry.fromJson(Map<String, dynamic> j) => PointsLogEntry(
        id: (j['id'] as num?)?.toInt() ?? 0,
        source: (j['source'] as String?) ?? '',
        points: (j['points'] as num?)?.toInt() ?? 0,
        description: j['description'] as String?,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'].toString())
            : null,
      );

  String get sourceLabel {
    switch (source) {
      case 'review':
        return 'Project review';
      case 'upvote':
        return 'Upvotes on your reviews';
      case 'referral_signup':
        return 'Referral signup';
      case 'referral_prime':
        return 'Referral went Prime';
      default:
        return source;
    }
  }
}

/// Aggregated points-by-source breakdown, as shown on the website's /profile.
class PointsSummary {
  final int totalPoints;
  final int fromReviews;
  final int fromUpvotes;
  final int fromReferralSignups;
  final int fromReferralPrime;

  const PointsSummary({
    required this.totalPoints,
    this.fromReviews = 0,
    this.fromUpvotes = 0,
    this.fromReferralSignups = 0,
    this.fromReferralPrime = 0,
  });

  factory PointsSummary.fromJson(Map<String, dynamic> j) {
    final bySource = (j['points_by_source'] as Map?)?.cast<String, dynamic>() ??
        (j['by_source'] as Map?)?.cast<String, dynamic>() ??
        {};
    int v(String k) => (bySource[k] as num?)?.toInt() ?? 0;
    return PointsSummary(
      totalPoints: (j['total_points'] as num?)?.toInt() ??
          (j['points'] as num?)?.toInt() ??
          (v('review') + v('upvote') + v('referral_signup') + v('referral_prime')),
      fromReviews: v('review'),
      fromUpvotes: v('upvote'),
      fromReferralSignups: v('referral_signup'),
      fromReferralPrime: v('referral_prime'),
    );
  }

  int get referralPoints => fromReferralSignups + fromReferralPrime;
}

/// Referral code + shareable link, as surfaced on the website's /profile.
class ReferralInfo {
  final String code;
  final String shareUrl;
  final int totalReferred;

  const ReferralInfo({
    required this.code,
    required this.shareUrl,
    this.totalReferred = 0,
  });

  factory ReferralInfo.fromJson(Map<String, dynamic> j) {
    final code = (j['referral_code'] as String?) ?? (j['code'] as String?) ?? '';
    return ReferralInfo(
      code: code,
      shareUrl: (j['share_url'] as String?) ??
          (code.isNotEmpty
              ? 'https://mjengohub.co.ke/register?ref=$code'
              : 'https://mjengohub.co.ke'),
      totalReferred: (j['total_referred'] as num?)?.toInt() ?? 0,
    );
  }
}
