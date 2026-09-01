// lib/reviews/models/review_model.dart
//
// Mirrors the inline dict in api.py's `GET /reviews` (ClientReview).
// Submitted reviews are held at `is_approved=False` until an admin approves
// them, so a freshly posted review will NOT appear in the list straight away.

class ClientReview {
  final int id;
  final String clientName;
  final int rating; // 1..5
  final String? reviewText;
  final String? clientImage;
  final bool isFeatured;
  final DateTime? createdAt;

  const ClientReview({
    required this.id,
    required this.clientName,
    required this.rating,
    this.reviewText,
    this.clientImage,
    this.isFeatured = false,
    this.createdAt,
  });

  factory ClientReview.fromJson(Map<String, dynamic> j) => ClientReview(
        id: (j['id'] as num?)?.toInt() ?? 0,
        clientName: (j['client_name'] as String?) ?? 'Anonymous',
        rating: (j['rating'] as num?)?.toInt() ?? 0,
        reviewText: j['review_text'] as String?,
        clientImage: j['client_image'] as String?,
        isFeatured: (j['is_featured'] as bool?) ?? false,
        createdAt: j['created_at'] != null
            ? DateTime.tryParse(j['created_at'] as String)
            : null,
      );
}
