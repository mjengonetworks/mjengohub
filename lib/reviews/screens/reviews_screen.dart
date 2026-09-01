// lib/reviews/screens/reviews_screen.dart
//
// Client reviews list + submit form, mirroring templates/reviews.html.
// Submitted reviews are held for admin approval, so a new review will not
// appear in the list immediately — the success message says so explicitly.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/responsive.dart';
import '../models/review_model.dart';
import '../services/reviews_service.dart';

class ReviewsScreen extends StatefulWidget {
  const ReviewsScreen({super.key});

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final _api = ReviewsService();

  List<ClientReview> _reviews = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final res = await _api.getReviews(perPage: 30);
    if (!mounted) return;
    setState(() {
      _reviews = res.items;
      _loading = false;
    });
  }

  Future<void> _openForm() async {
    final submitted = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => _ReviewForm(api: _api),
    );
    // New reviews need admin approval before they appear, so this refresh
    // usually won't show the one just submitted — it keeps the list honest if
    // other reviews were approved in the meantime.
    if (submitted == true && mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          'Reviews',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        onPressed: _openForm,
        icon: const Icon(Icons.rate_review_outlined, color: Colors.white),
        label: Text(
          'Write a review',
          style: GoogleFonts.montserrat(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _reviews.isEmpty
                ? _empty()
                : ContentWidth(
                    child: ListView.separated(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 90),
                      itemCount: _reviews.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) => _ReviewCard(review: _reviews[i]),
                    ),
                  ),
      ),
    );
  }

  Widget _empty() => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        children: [
          const Icon(Icons.rate_review_outlined, size: 44, color: AppColors.textSubtle),
          const SizedBox(height: 14),
          Text(
            'No reviews yet',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Be the first to share your experience.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.textSubtle),
          ),
        ],
      );
}

/// Five-star row. [size] keeps it usable both as a display and inside the form.
class StarRow extends StatelessWidget {
  const StarRow({super.key, required this.rating, this.size = 15, this.onTap});

  final int rating;
  final double size;
  final ValueChanged<int>? onTap;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(5, (i) {
          final filled = i < rating;
          final star = Icon(
            filled ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: filled ? AppColors.warning : AppColors.textSubtle,
          );
          if (onTap == null) return star;
          return GestureDetector(
            onTap: () => onTap!(i + 1),
            behavior: HitTestBehavior.opaque,
            child: Padding(padding: const EdgeInsets.only(right: 2), child: star),
          );
        }),
      );
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review});

  final ClientReview review;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.card),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (review.clientImage != null && review.clientImage!.isNotEmpty)
                NetImage(
                  url: review.clientImage,
                  width: 38,
                  height: 38,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                )
              else
                Container(
                  width: 38,
                  height: 38,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.divider,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    review.clientName.isNotEmpty
                        ? review.clientName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.clientName,
                      style: GoogleFonts.montserrat(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 3),
                    StarRow(rating: review.rating),
                  ],
                ),
              ),
              if (review.isFeatured)
                const Icon(Icons.workspace_premium,
                    size: 17, color: AppColors.primaryBlue),
            ],
          ),
          if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.reviewText!,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                height: 1.6,
                color: AppColors.textDark,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bottom-sheet review form. Kept in this file because it is only ever opened
/// from [ReviewsScreen].
class _ReviewForm extends StatefulWidget {
  const _ReviewForm({required this.api});

  final ReviewsService api;

  @override
  State<_ReviewForm> createState() => _ReviewFormState();
}

class _ReviewFormState extends State<_ReviewForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _text = TextEditingController();

  int _rating = 5;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _text.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final res = await widget.api.submitReview(
      clientName: _name.text.trim(),
      clientEmail: _email.text.trim(),
      reviewText: _text.text.trim(),
      rating: _rating,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    final ok = res['success'] == true;
    Navigator.of(context).pop(ok);
    Get.snackbar(
      ok ? 'Thank you' : 'Could not submit',
      res['message'] as String? ?? (ok ? 'Review submitted.' : 'Please try again.'),
      backgroundColor: ok ? AppColors.success : AppColors.danger,
      colorText: Colors.white,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(12),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Write a review',
                style: GoogleFonts.montserrat(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textDark,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Reviews are published once approved by our team.',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 18),

              const FieldLabel('Your rating', required: true),
              StarRow(
                rating: _rating,
                size: 30,
                onTap: (v) => setState(() => _rating = v),
              ),
              const SizedBox(height: 16),

              const FieldLabel('Name', required: true),
              AppTextField(
                controller: _name,
                hint: 'Your name',
                validator: (v) => requiredField(v, 'Name'),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Email', required: true),
              AppTextField(
                controller: _email,
                hint: 'you@example.com',
                keyboard: TextInputType.emailAddress,
                textCapitalization: TextCapitalization.none,
                validator: emailField,
              ),
              const SizedBox(height: 14),

              const FieldLabel('Your review', required: true),
              AppTextField(
                controller: _text,
                hint: 'Tell others about your experience',
                maxLines: 5,
                validator: (v) => requiredField(v, 'Review'),
              ),
              const SizedBox(height: 22),

              AppSubmitButton(
                label: 'Submit review',
                busy: _submitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
