// lib/auth/models/user_model.dart
//
// Mirrors api.py's `_user_dict` — the only user shape the live backend
// returns (`auth/register`, `auth/login`, `auth/me`).
//
// The previous version of this file carried a large marketplace/shop layer
// (ShopDetails, ShopDocuments, userType, trustBadges, totalSales…) and a
// Firebase 2FA layer (twoFAEnabled, twoFAMethod), both left over from the
// retired Firebase `UserController` stack. None of it was read anywhere in the
// app and none of it exists in the API response, so it has been removed rather
// than left to look like live state. `UserValidator` went with it (also unused).
import '../../point/models/points_models.dart';

class UserModel {
  /// Backend `id`, stringified. Named `uid` for continuity with the screens
  /// that already read it.
  final String uid;
  final String? email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? photoURL;
  final String? coverImageUrl;
  final String? bio;
  final String? location;
  final String? company;

  /// Backend `role` (e.g. 'USER', 'ADMIN', 'EDITOR') — serialised from the
  /// Flask enum as a plain string.
  final String? role;

  /// How the account was created. The API doesn't return this; it stays here
  /// because the UI distinguishes email vs Google sign-in copy.
  final String? provider;

  final DateTime? createdAt;
  final bool isActive;

  // ── Gamification / Mjengo Hub Prime ─────────────────────────────────────
  /// Cumulative reputation points (source of truth is the backend PointsLog).
  final int points;
  final String? referralCode;
  final String? referredById;

  /// Admin-granted "verified" flag — the underlying field for Mjengo Hub
  /// Prime. Paired with [verificationExpiresAt] for paid subscriptions.
  final bool isVerified;
  final DateTime? verificationExpiresAt;

  const UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.photoURL,
    this.coverImageUrl,
    this.bio,
    this.location,
    this.company,
    this.role,
    this.provider,
    this.createdAt,
    this.isActive = true,
    this.points = 0,
    this.referralCode,
    this.referredById,
    this.isVerified = false,
    this.verificationExpiresAt,
  });

  /// Parses api.py's `_user_dict`. Also used for the `shared_preferences`
  /// user cache, which stores that same JSON verbatim.
  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        uid: json['id']?.toString() ?? '',
        email: json['email'] as String?,
        displayName: (json['display_name'] as String?) ?? (json['name'] as String?),
        firstName: json['first_name'] as String?,
        lastName: json['last_name'] as String?,
        phoneNumber: json['phone'] as String?,
        photoURL: json['profile_image'] as String?,
        coverImageUrl: json['cover_image'] as String?,
        bio: json['bio'] as String?,
        location: json['location'] as String?,
        company: json['company'] as String?,
        role: json['role']?.toString(),
        // Not part of `_user_dict`; defaulted so existing UI copy still works.
        provider: json['provider'] as String? ?? 'email',
        isActive: json['is_active'] as bool? ?? true,
        points: (json['points'] as num?)?.toInt() ?? 0,
        referralCode: json['referral_code'] as String?,
        referredById: json['referred_by_id']?.toString(),
        isVerified: json['is_verified'] as bool? ?? false,
        verificationExpiresAt: _parseDate(json['verification_expires_at']),
        createdAt: _parseDate(json['created_at']) ?? _parseDate(json['joined_at']),
      );

  /// Serialises back to the API's snake_case shape.
  Map<String, dynamic> toJson() => {
        'id': uid,
        'email': email,
        'first_name': firstName,
        'last_name': lastName,
        'phone': phoneNumber,
        'profile_image': photoURL,
        'cover_image': coverImageUrl,
        'bio': bio,
        'location': location,
        'company': company,
        'role': role,
        'points': points,
        'referral_code': referralCode,
        'referred_by_id': referredById,
        'is_verified': isVerified,
        'verification_expires_at': verificationExpiresAt?.toIso8601String(),
        'created_at': createdAt?.toIso8601String(),
      };

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? photoURL,
    String? coverImageUrl,
    String? bio,
    String? location,
    String? company,
    String? role,
    String? provider,
    DateTime? createdAt,
    bool? isActive,
    int? points,
    String? referralCode,
    String? referredById,
    bool? isVerified,
    DateTime? verificationExpiresAt,
  }) =>
      UserModel(
        uid: uid ?? this.uid,
        email: email ?? this.email,
        displayName: displayName ?? this.displayName,
        firstName: firstName ?? this.firstName,
        lastName: lastName ?? this.lastName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        photoURL: photoURL ?? this.photoURL,
        coverImageUrl: coverImageUrl ?? this.coverImageUrl,
        bio: bio ?? this.bio,
        location: location ?? this.location,
        company: company ?? this.company,
        role: role ?? this.role,
        provider: provider ?? this.provider,
        createdAt: createdAt ?? this.createdAt,
        isActive: isActive ?? this.isActive,
        points: points ?? this.points,
        referralCode: referralCode ?? this.referralCode,
        referredById: referredById ?? this.referredById,
        isVerified: isVerified ?? this.isVerified,
        verificationExpiresAt: verificationExpiresAt ?? this.verificationExpiresAt,
      );

  // ── Computed helpers ───────────────────────────────────────────────────────

  String get initials {
    if (firstName != null && firstName!.isNotEmpty && lastName != null && lastName!.isNotEmpty) {
      return '${firstName![0]}${lastName![0]}'.toUpperCase();
    }
    if (displayName != null && displayName!.isNotEmpty) {
      final names = displayName!.trim().split(RegExp(r'\s+'));
      if (names.length >= 2 && names[1].isNotEmpty) {
        return '${names[0][0]}${names[1][0]}'.toUpperCase();
      }
      return names[0][0].toUpperCase();
    }
    if (firstName != null && firstName!.isNotEmpty) return firstName![0].toUpperCase();
    if (email != null && email!.isNotEmpty) return email![0].toUpperCase();
    return '?';
  }

  String get displayNameOrFallback {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (firstName != null && lastName != null) return '$firstName $lastName'.trim();
    if (firstName != null) return firstName!;
    if (email != null) return email!;
    if (phoneNumber != null) return phoneNumber!;
    return 'User';
  }

  String? get fullName {
    if (firstName != null && lastName != null) return '$firstName $lastName'.trim();
    return displayName ?? firstName;
  }

  bool get isEmailUser => provider == 'email';
  bool get isGoogleUser => provider == 'google';
  bool get isAdmin => (role ?? '').toUpperCase() == 'ADMIN';

  /// Mjengo Hub Prime status — verified AND (no expiry, or not yet expired).
  /// Mirrors `User.is_currently_verified` on the Flask backend.
  bool get isPrime {
    if (!isVerified) return false;
    if (verificationExpiresAt == null) return true;
    return verificationExpiresAt!.isAfter(DateTime.now());
  }

  /// Reviewer level (Google Local Guides-style badge), derived live from
  /// [points] exactly like the website's `points_level_info` property.
  ReviewerLevel get reviewerLevel => ReviewerLevel.forPoints(points);

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
    return DateTime.tryParse(value.toString());
  }

  @override
  String toString() =>
      'UserModel(uid: $uid, email: $email, name: $fullName, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is UserModel && other.uid == uid);

  @override
  int get hashCode => uid.hashCode;
}
