// lib/merch/models/merch_model.dart
//
// `GET /merch/products` and `GET /merch/shoutouts` — read-only catalog and
// approved buyer shoutouts. Checkout itself is a WebView handoff into the
// existing web `/merch` cart+checkout flow (see WebviewCheckoutScreen); no
// cart/order model exists client-side because there's nothing to compute —
// the web app owns that state entirely.
class MerchProduct {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final double price;
  final String? image;
  final bool isInStock;

  /// Trinity platform this product belongs to: 'mjengohub' /
  /// 'sharebarabara' / 'mjengonetworks'. Not sent by the live
  /// `GET merch/products` today — every sampled product comes back with no
  /// `platform` key at all, and the catalog is 100% Mjengo Hub-branded items
  /// (pen/jacket/t-shirt/hoodie), so this defaults to 'mjengohub' rather
  /// than guessing from the name/description. The Share Barabara / Mjengo
  /// Networks filter tabs are real UI, just backed by an empty catalog
  /// until the backend actually stocks products for those platforms.
  final String platform;

  const MerchProduct({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.image,
    required this.isInStock,
    this.platform = 'mjengohub',
  });

  factory MerchProduct.fromJson(Map<String, dynamic> j) => MerchProduct(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
        description: j['description'] as String?,
        price: (j['price'] as num?)?.toDouble() ?? 0,
        image: j['image'] as String?,
        isInStock: j['is_in_stock'] as bool? ?? false,
        platform: (j['platform'] as String?) ?? 'mjengohub',
      );
}

class MerchShoutout {
  final int id;
  final String? userName;
  final String? userAvatar;
  final String? message;
  final String? createdAt;

  const MerchShoutout({required this.id, this.userName, this.userAvatar, this.message, this.createdAt});

  factory MerchShoutout.fromJson(Map<String, dynamic> j) => MerchShoutout(
        id: (j['id'] as num?)?.toInt() ?? 0,
        userName: j['user_name'] as String?,
        userAvatar: j['user_avatar'] as String?,
        message: j['message'] as String?,
        createdAt: j['created_at'] as String?,
      );
}
