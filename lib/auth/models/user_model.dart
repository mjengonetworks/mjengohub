/// User model class with phone authentication support + 2FA fields
class UserModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String? photoURL;
  final String? bio;
  final String? location;
  final String? company;
  final String? provider;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool isActive;
  final bool? emailVerified;
  final Map<String, dynamic>? additionalData;

  // Marketplace specific fields
  final String userType; // 'individual' or 'shop'
  final double rating;
  final int totalReviews;
  final int totalSales;
  final int totalPurchases;
  final bool blocked;

  // Shop-specific fields (only for userType: "shop")
  final ShopDetails? shopDetails;

  // Verification / trust badges (individual sellers)
  final String verificationTier;
  final List<String> trustBadges;

  // ── 2FA fields ─────────────────────────────────────────────────────────────
  /// Whether 2FA is enabled at the backend / profile level.
  final bool twoFAEnabled;

  /// The enrolled 2FA method: 'totp' | 'sms' | ''
  final String twoFAMethod;

  UserModel({
    required this.uid,
    this.email,
    this.displayName,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    this.photoURL,
    this.bio,
    this.location,
    this.company,
    this.provider,
    this.createdAt,
    this.updatedAt,
    this.isActive = true,
    this.emailVerified,
    this.additionalData,
    this.userType = 'individual',
    this.rating = 0.0,
    this.totalReviews = 0,
    this.totalSales = 0,
    this.totalPurchases = 0,
    this.blocked = false,
    this.shopDetails,
    this.verificationTier = 'unverified',
    this.trustBadges = const [],
    this.twoFAEnabled = false,
    this.twoFAMethod = '',
  });

  /// Create UserModel from JSON (from API response)
  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Backend stores 'id' (from Firestore doc), Flutter model uses 'uid'
    final uid = json['uid'] as String?
        ?? json['id'] as String?
        ?? '';
    // Backend uses 'isVerified'; Firebase uses 'emailVerified'
    final emailVerified = json['emailVerified'] as bool?
        ?? json['isVerified'] as bool?;
    // Backend uses 'isSuspended'; model uses 'blocked'
    final blocked = json['blocked'] as bool?
        ?? json['isSuspended'] as bool?
        ?? false;
    // Backend uses 'phone'; model uses 'phoneNumber'
    final phoneNumber = json['phoneNumber'] as String?
        ?? json['phone'] as String?;

    return UserModel(
      uid: uid,
      email: json['email'] as String?,
      displayName: json['displayName'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phoneNumber: phoneNumber,
      photoURL: json['photoURL'] as String?,
      bio: json['bio'] as String?,
      location: json['location'] as String?,
      company: json['company'] as String?,
      provider: json['provider'] as String?,
      createdAt: json['createdAt'] != null ? _parseTimestamp(json['createdAt']) : null,
      updatedAt: json['updatedAt'] != null ? _parseTimestamp(json['updatedAt']) : null,
      isActive: json['isActive'] as bool? ?? true,
      emailVerified: emailVerified,
      additionalData: json['additionalData'] as Map<String, dynamic>?,
      userType: json['userType'] as String? ?? 'individual',
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      totalReviews: json['totalReviews'] as int? ?? 0,
      totalSales: json['totalSales'] as int? ?? 0,
      totalPurchases: json['totalPurchases'] as int? ?? 0,
      blocked: blocked,
      shopDetails: json['shopDetails'] != null
          ? ShopDetails.fromJson(json['shopDetails'] as Map<String, dynamic>)
          : null,
      verificationTier: json['verificationTier'] as String? ?? 'unverified',
      trustBadges: (json['trustBadges'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      twoFAEnabled: json['twoFAEnabled'] as bool? ?? false,
      twoFAMethod: json['twoFAMethod'] as String? ?? '',
    );
  }

  /// Convert UserModel to JSON (for API requests)
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'photoURL': photoURL,
      'bio': bio,
      'location': location,
      'company': company,
      'provider': provider,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'isActive': isActive,
      'emailVerified': emailVerified,
      'additionalData': additionalData,
      'userType': userType,
      'rating': rating,
      'totalReviews': totalReviews,
      'totalSales': totalSales,
      'totalPurchases': totalPurchases,
      'blocked': blocked,
      'shopDetails': shopDetails?.toJson(),
      'verificationTier': verificationTier,
      'trustBadges': trustBadges,
      'twoFAEnabled': twoFAEnabled,
      'twoFAMethod': twoFAMethod,
    };
  }

  /// Create a copy of UserModel with modified fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    String? photoURL,
    String? bio,
    String? location,
    String? company,
    String? provider,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? emailVerified,
    Map<String, dynamic>? additionalData,
    String? userType,
    double? rating,
    int? totalReviews,
    int? totalSales,
    int? totalPurchases,
    bool? blocked,
    ShopDetails? shopDetails,
    String? verificationTier,
    List<String>? trustBadges,
    bool? twoFAEnabled,
    String? twoFAMethod,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      photoURL: photoURL ?? this.photoURL,
      bio: bio ?? this.bio,
      location: location ?? this.location,
      company: company ?? this.company,
      provider: provider ?? this.provider,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      emailVerified: emailVerified ?? this.emailVerified,
      additionalData: additionalData ?? this.additionalData,
      userType: userType ?? this.userType,
      rating: rating ?? this.rating,
      totalReviews: totalReviews ?? this.totalReviews,
      totalSales: totalSales ?? this.totalSales,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      blocked: blocked ?? this.blocked,
      shopDetails: shopDetails ?? this.shopDetails,
      verificationTier: verificationTier ?? this.verificationTier,
      trustBadges: trustBadges ?? this.trustBadges,
      twoFAEnabled: twoFAEnabled ?? this.twoFAEnabled,
      twoFAMethod: twoFAMethod ?? this.twoFAMethod,
    );
  }

  // ── Computed helpers ───────────────────────────────────────────────────────

  String get initials {
    if (firstName != null && lastName != null) return '${firstName![0]}${lastName![0]}'.toUpperCase();
    if (displayName != null && displayName!.isNotEmpty) {
      final names = displayName!.split(' ');
      if (names.length >= 2) return '${names[0][0]}${names[1][0]}'.toUpperCase();
      return names[0][0].toUpperCase();
    }
    if (email != null) return email![0].toUpperCase();
    if (phoneNumber != null) return phoneNumber![phoneNumber!.length - 2].toUpperCase();
    return '?';
  }

  String get displayNameOrFallback {
    if (displayName != null && displayName!.isNotEmpty) return displayName!;
    if (firstName != null && lastName != null) return '$firstName $lastName';
    if (firstName != null) return firstName!;
    if (email != null) return email!;
    if (phoneNumber != null) return phoneNumber!;
    return 'User';
  }

  String? get fullName {
    if (firstName != null && lastName != null) return '$firstName $lastName';
    return displayName;
  }

  bool get isPhoneUser => provider == 'phone';
  bool get isEmailUser => provider == 'email';
  bool get isGoogleUser => provider == 'google';
  bool get isIndividual => userType == 'individual';
  bool get isShop => userType == 'shop';
  bool get hasPendingShopApplication => shopDetails?.verificationStatus == 'pending';
  bool get isVerifiedShop => isShop && (shopDetails?.isActive ?? false);
  bool get hasIdVerified => trustBadges.contains('id_verified');
  bool get isTrustedSeller => trustBadges.contains('trusted_seller');
  bool get isPhoneVerifiedBadge => trustBadges.contains('phone_verified');

  /// Whether 2FA is active on this account.
  bool get has2FA => twoFAEnabled;

  /// Human-readable label for the active 2FA method.
  String get twoFAMethodLabel {
    switch (twoFAMethod) {
      case 'totp': return 'Authenticator App';
      case 'sms': return 'SMS';
      default: return 'None';
    }
  }

  static DateTime? _parseTimestamp(dynamic timestamp) {
    if (timestamp == null) return null;
    try {
      if (timestamp is Map<String, dynamic> &&
          timestamp.containsKey('_seconds') &&
          timestamp.containsKey('_nanoseconds')) {
        final seconds = timestamp['_seconds'] as int;
        final nanoseconds = timestamp['_nanoseconds'] as int;
        return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds / 1000000).round());
      }
      if (timestamp is String) return DateTime.parse(timestamp);
      if (timestamp is int) return DateTime.fromMillisecondsSinceEpoch(timestamp);
      return null;
    } catch (e) {
      print('Error parsing timestamp: $e');
      return null;
    }
  }

  @override
  String toString() => 'UserModel(uid: $uid, phone: $phoneNumber, email: $email, name: $fullName, 2FA: $twoFAEnabled)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

/// User validation helper
class UserValidator {
  static String? validateEmail(String? email) {
    if (email == null || email.isEmpty) return null;
    final emailRegex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    if (!emailRegex.hasMatch(email)) return 'Please enter a valid email address';
    return null;
  }

  static String? validatePhoneNumber(String? phoneNumber) {
    if (phoneNumber == null || phoneNumber.isEmpty) return 'Phone number is required';
    final digitsOnly = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 10 || digitsOnly.length > 15) return 'Please enter a valid phone number';
    return null;
  }

  static String? validateFirstName(String? firstName) {
    if (firstName == null || firstName.isEmpty) return 'First name is required';
    if (firstName.length < 2) return 'First name must be at least 2 characters';
    if (firstName.length > 50) return 'First name must not exceed 50 characters';
    return null;
  }

  static String? validateLastName(String? lastName) {
    if (lastName == null || lastName.isEmpty) return 'Last name is required';
    if (lastName.length < 2) return 'Last name must be at least 2 characters';
    if (lastName.length > 50) return 'Last name must not exceed 50 characters';
    return null;
  }

  static String? validatePassword(String? password) {
    if (password == null || password.isEmpty) return null;
    if (password.length < 6) return 'Password must be at least 6 characters long';
    return null;
  }

  static String? validateDisplayName(String? displayName) {
    if (displayName == null || displayName.isEmpty) return null;
    if (displayName.length < 2) return 'Display name must be at least 2 characters';
    if (displayName.length > 50) return 'Display name must not exceed 50 characters';
    return null;
  }
}

/// Shop details model for verified business accounts
class ShopDetails {
  final String businessName;
  final String? businessDescription;
  final String businessAddress;
  final String? businessEmail;
  final String businessPhone;
  final String county;
  final String? subCounty;
  final ShopDocuments? documents;
  final String verificationStatus;
  final String? verificationTier;
  final String? trustBadge;
  final String? verificationNotes;
  final DateTime? verifiedAt;
  final String? verifiedBy;
  final double shopRating;
  final int totalShopReviews;
  final int totalShopSales;
  final bool isActive;
  final bool isSuspended;
  final DateTime? submittedAt;

  ShopDetails({
    required this.businessName,
    this.businessDescription,
    required this.businessAddress,
    this.businessEmail,
    required this.businessPhone,
    required this.county,
    this.subCounty,
    this.documents,
    this.verificationStatus = 'pending',
    this.verificationTier,
    this.trustBadge,
    this.verificationNotes,
    this.verifiedAt,
    this.verifiedBy,
    this.shopRating = 0.0,
    this.totalShopReviews = 0,
    this.totalShopSales = 0,
    this.isActive = false,
    this.isSuspended = false,
    this.submittedAt,
  });

  factory ShopDetails.fromJson(Map<String, dynamic> json) {
    return ShopDetails(
      businessName: json['businessName'] as String? ?? '',
      businessDescription: json['businessDescription'] as String?,
      businessAddress: json['businessAddress'] as String? ?? '',
      businessEmail: json['businessEmail'] as String?,
      businessPhone: json['businessPhone'] as String? ?? '',
      county: json['county'] as String? ?? '',
      subCounty: json['subCounty'] as String?,
      documents: json['documents'] != null
          ? ShopDocuments.fromJson(json['documents'] as Map<String, dynamic>)
          : null,
      verificationStatus: json['verificationStatus'] as String? ?? 'pending',
      verificationTier: json['verificationTier'] as String?,
      trustBadge: json['trustBadge'] as String?,
      verificationNotes: json['verificationNotes'] as String?,
      verifiedAt: json['verifiedAt'] != null ? UserModel._parseTimestamp(json['verifiedAt']) : null,
      verifiedBy: json['verifiedBy'] as String?,
      shopRating: (json['shopRating'] as num?)?.toDouble() ?? 0.0,
      totalShopReviews: json['totalShopReviews'] as int? ?? 0,
      totalShopSales: json['totalShopSales'] as int? ?? 0,
      isActive: json['isActive'] as bool? ?? false,
      isSuspended: json['isSuspended'] as bool? ?? false,
      submittedAt: json['submittedAt'] != null ? UserModel._parseTimestamp(json['submittedAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'businessName': businessName,
      'businessDescription': businessDescription,
      'businessAddress': businessAddress,
      'businessEmail': businessEmail,
      'businessPhone': businessPhone,
      'county': county,
      'subCounty': subCounty,
      'documents': documents?.toJson(),
      'verificationStatus': verificationStatus,
      'verificationTier': verificationTier,
      'trustBadge': trustBadge,
      'verificationNotes': verificationNotes,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'verifiedBy': verifiedBy,
      'shopRating': shopRating,
      'totalShopReviews': totalShopReviews,
      'totalShopSales': totalShopSales,
      'isActive': isActive,
      'isSuspended': isSuspended,
      'submittedAt': submittedAt?.toIso8601String(),
    };
  }
}

/// Shop documents model
class ShopDocuments {
  final String? kraPinCertificate;
  final String? businessRegistration;
  final String? countyPermit;
  final String? ownerId;
  final List<String> businessPhotos;

  ShopDocuments({
    this.kraPinCertificate,
    this.businessRegistration,
    this.countyPermit,
    this.ownerId,
    this.businessPhotos = const [],
  });

  factory ShopDocuments.fromJson(Map<String, dynamic> json) {
    return ShopDocuments(
      kraPinCertificate: json['kraPinCertificate'] as String?,
      businessRegistration: json['businessRegistration'] as String?,
      countyPermit: json['countyPermit'] as String?,
      ownerId: json['ownerId'] as String?,
      businessPhotos: (json['businessPhotos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'kraPinCertificate': kraPinCertificate,
      'businessRegistration': businessRegistration,
      'countyPermit': countyPermit,
      'ownerId': ownerId,
      'businessPhotos': businessPhotos,
    };
  }
}