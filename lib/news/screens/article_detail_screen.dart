import '../../shared/widgets/social_share_modal.dart';
import '../../shared/services/bookmarks_service.dart';
// lib/news/screens/article_detail_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../controllers/article_detail_controller.dart';
import '../models/article_model.dart';
import '../widgets/net_image.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({Key? key}) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late final ArticleDetailController _ctrl;
  bool _isSaved = false;

  void _checkSaved(String slug) async {
    final saved = await BookmarksService.isBookmarked(slug);
    if (mounted) setState(() => _isSaved = saved);
  }

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ArticleDetailController());
    final slug = Get.arguments as String? ?? '';
    _ctrl.loadArticle(slug);
    _checkSaved(slug);
  }

  @override
  void dispose() {
    Get.delete<ArticleDetailController>(force: true);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Obx(() {
          if (_ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor:
                    AlwaysStoppedAnimation<Color>(Color(0xFF111827)),
              ),
            );
          }
          if (_ctrl.errorMessage.isNotEmpty || _ctrl.article.value == null) {
            return _ErrorView(message: _ctrl.errorMessage.value);
          }
          return _ArticleBody(article: _ctrl.article.value!);
        }),
      ),
    );
  }
}

// -- Article body (collapsing hero + content) ----------------------------------

class _ArticleBody extends StatelessWidget {
  final Article article;
  const _ArticleBody({required this.article});

  static const double _heroHeight = 360.0;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // -- Collapsing hero ----------------------------------------------
        SliverAppBar(
          expandedHeight: _heroHeight,
          pinned: true,
          backgroundColor: Colors.black,
          elevation: 0,
          leading: _backButton(),
          actions: [_bookmarkButton(article), _shareButton(article)],
          flexibleSpace: FlexibleSpaceBar(
            background: _HeroImage(article: article),
            collapseMode: CollapseMode.parallax,
          ),
        ),

        // -- Content ------------------------------------------------------
        SliverToBoxAdapter(
          child: _ContentSection(article: article),
        ),
      ],
    );
  }

  Widget _backButton() {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: GestureDetector(
        onTap: Get.back,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.arrow_back_rounded,
              color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _bookmarkButton(Article article) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
      child: GestureDetector(
        onTap: () async {
          final nowSaved = await BookmarksService.toggleBookmark(
            BookmarkedItem(
              id: article.id.toString(),
              title: article.title,
              slug: article.slug,
              imageUrl: article.imageUrl,
              category: article.category?.name,
              type: 'article',
              savedAt: DateTime.now(),
            ),
          );
          if (mounted) {
            setState(() => _isSaved = nowSaved);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(nowSaved ? 'Article saved to bookmarks' : 'Article removed from bookmarks'),
                duration: const Duration(seconds: 2),
              ),
            );
          }
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: _isSaved ? const Color(0xFFF59E0B) : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _shareButton(Article article) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: GestureDetector(
        onTap: () => _shareArticle(article),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.35),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  void _shareArticle(Article article) {
    final url = 'https://mjengohub.co.ke/news/${article.slug}';
    SocialShareModal.show(
      context,
      title: 'Read this on Mjengo Hub: "${article.title}"',
      url: url,
    );
  }
}

// -- Hero image with gradient & overlay text -----------------------------------

class _HeroImage extends StatelessWidget {
  final Article article;
  const _HeroImage({required this.article});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Image
        NetImage(
          url: article.imageUrl,
          fit: BoxFit.cover,
          placeholderColor: const Color(0xFF1F2937),
        ),

        // Gradient overlay
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x33000000), Color(0xBB000000)],
              stops: [0.3, 1.0],
            ),
          ),
        ),

        // Category badge + title at bottom of hero
        Positioned(
          left: 20,
          right: 20,
          bottom: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (article.category != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF374151),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    article.category!.name,
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Text(
                article.title,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// -- Content below hero --------------------------------------------------------

class _ContentSection extends StatelessWidget {
  final Article article;
  const _ContentSection({required this.article});

  @override
  Widget build(BuildContext context) {
    final hasContent = article.plainContent.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // -- Author + meta row ------------------------------------------
          _AuthorRow(article: article),
          const SizedBox(height: 20),

          // -- Divider ----------------------------------------------------
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 20),

          // -- Summary ----------------------------------------------------
          if (article.summary != null && article.summary!.isNotEmpty) ...[
            Text(
              article.summary!,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: const Color(0xFF374151),
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // -- Body text --------------------------------------------------
          if (hasContent)
            Text(
              article.plainContent,
              style: GoogleFonts.montserrat(
                fontSize: 15,
                color: const Color(0xFF4B5563),
                height: 1.7,
              ),
            ),

          // -- Image caption ----------------------------------------------
          if (article.featuredImageCaption != null &&
              article.featuredImageCaption!.isNotEmpty) ...[
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Text(
                article.featuredImageCaption!,
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  color: const Color(0xFF6B7280),
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}

// -- Author row ----------------------------------------------------------------

class _AuthorRow extends StatelessWidget {
  final Article article;
  const _AuthorRow({required this.article});

  @override
  Widget build(BuildContext context) {
    final author = article.author;

    return Row(
      children: [
        // Avatar
        if (author != null) ...[
          ClipOval(
            child: NetImage(
              url: author.imageUrl,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              placeholderColor: const Color(0xFF374151),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              author.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF111827),
              ),
            ),
          ),
        ] else
          const Expanded(child: SizedBox.shrink()),

        // Read time
        if (article.readTime != null) ...[
          const Icon(Icons.access_time_rounded,
              size: 14, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 4),
          Text(
            '${article.readTime} min',
            style: GoogleFonts.montserrat(
                fontSize: 12.5, color: const Color(0xFF9CA3AF)),
          ),
          const SizedBox(width: 12),
        ],

        // View count
        const Icon(Icons.remove_red_eye_outlined,
            size: 14, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 4),
        Text(
          article.formattedViews,
          style: GoogleFonts.montserrat(
              fontSize: 12.5, color: const Color(0xFF9CA3AF)),
        ),
      ],
    );
  }
}

// -- Error view ----------------------------------------------------------------

class _ErrorView extends StatelessWidget {
  final String message;
  const _ErrorView({required this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.article_outlined,
                size: 52, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              message.isEmpty ? 'Article not found.' : message,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: Get.back,
              child: Text('Go back',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}


