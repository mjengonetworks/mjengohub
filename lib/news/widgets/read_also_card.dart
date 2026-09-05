// lib/news/widgets/read_also_card.dart
//
// Mid-article "Read Also" card (parity with the website's `read-also-card`,
// injected server-side by `inject_read_also()` in application.py). That
// injection happens at Jinja render time from a randomly-picked related
// article and is never part of the stored `article.content` HTML the API
// returns — so there is nothing to "intercept" from the API payload itself.
// This widget reproduces the same visual/behavioral feature (one related
// article, orange left accent bar, tap to open natively) by picking a
// same-category article from the live API instead, the same honest
// same-category-fallback approach already used elsewhere in this app
// (e.g. built_history_screen.dart's "From the Archives" section).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../models/article_model.dart';
import '../services/news_api_service.dart';

class ReadAlsoCard extends StatefulWidget {
  final Article article;
  const ReadAlsoCard({super.key, required this.article});

  @override
  State<ReadAlsoCard> createState() => _ReadAlsoCardState();
}

class _ReadAlsoCardState extends State<ReadAlsoCard> {
  final _service = NewsApiService();
  Article? _related;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final categorySlug = widget.article.category?.slug;
    var candidates = await _service.getArticles(categorySlug: categorySlug, perPage: 6);
    candidates = candidates.where((a) => a.id != widget.article.id).toList();
    if (candidates.isEmpty && categorySlug != null) {
      // Category had nothing else — widen to the general latest list.
      final fallback = await _service.getArticles(perPage: 6);
      candidates = fallback.where((a) => a.id != widget.article.id).toList();
    }
    if (!mounted) return;
    setState(() {
      _related = candidates.isNotEmpty ? candidates.first : null;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || _related == null) return const SizedBox.shrink();
    final related = _related!;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.articleDetail, arguments: related.slug),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 10),
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          border: const Border(left: BorderSide(color: Color(0xFFF97316), width: 4)),
          borderRadius: BorderRadius.circular(AppRadius.sharp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'READ ALSO',
              style: GoogleFonts.montserrat(fontSize: 10.5, fontWeight: FontWeight.w800, color: const Color(0xFFF97316), letterSpacing: 0.6),
            ),
            const SizedBox(height: 4),
            Text(
              related.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.headingSlate, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}
