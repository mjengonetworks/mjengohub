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

  const MerchProduct({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    this.image,
    required this.isInStock,
  });

  factory MerchProduct.fromJson(Map<String, dynamic> j) => MerchProduct(
        id: (j['id'] as num?)?.toInt() ?? 0,
        name: (j['name'] as String?) ?? '',
        slug: (j['slug'] as String?) ?? '',
        description: j['description'] as String?,
        price: (j['price'] as num?)?.toDouble() ?? 0,
        image: j['image'] as String?,
        isInStock: j['is_in_stock'] as bool? ?? false,
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
