import '../../shared/widgets/social_share_modal.dart';
import '../../shared/services/bookmarks_service.dart';
// lib/news/screens/article_detail_screen.dart
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../comments/services/comments_service.dart';
import '../../comments/widgets/comments_section.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../controllers/article_detail_controller.dart';
import '../models/article_content_blocks.dart';
import '../models/article_model.dart';
import '../widgets/article_discovery_section.dart';
import '../widgets/article_map_embed.dart';
import '../widgets/net_image.dart';
import '../widgets/read_also_card.dart';
import '../widgets/tagged_project_card.dart';
import '../../shared/widgets/scroll_to_top_fab.dart';

class ArticleDetailScreen extends StatefulWidget {
  const ArticleDetailScreen({Key? key}) : super(key: key);

  @override
  State<ArticleDetailScreen> createState() => _ArticleDetailScreenState();
}

class _ArticleDetailScreenState extends State<ArticleDetailScreen> {
  late final ArticleDetailController _ctrl;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ctrl = Get.put(ArticleDetailController());
    final slug = Get.arguments as String? ?? '';
    _ctrl.loadArticle(slug);
  }

  @override
  void dispose() {
    Get.delete<ArticleDetailController>(force: true);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        // Clean off-white editorial backdrop.
        backgroundColor: const Color(0xFFF8FAFC),
        body: ScrollToTopFab(
          controller: _scrollController,
          child: Obx(() {
          if (_ctrl.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF111827)),
              ),
            );
          }
          if (_ctrl.errorMessage.isNotEmpty || _ctrl.article.value == null) {
            return _ErrorView(message: _ctrl.errorMessage.value);
          }
          return _ArticleBody(article: _ctrl.article.value!, scrollController: _scrollController);
        }),
        ),
      ),
    );
  }
}

// -- Article body (collapsing hero + content) ----------------------------------

class _ArticleBody extends StatefulWidget {
  final Article article;
  final ScrollController? scrollController;
  const _ArticleBody({required this.article, this.scrollController});

  @override
  State<_ArticleBody> createState() => _ArticleBodyState();
}

class _ArticleBodyState extends State<_ArticleBody> {
  bool _isSaved = false;
  late final List<ArticleContentBlock> _blocks;

  @override
  void initState() {
    super.initState();
    _blocks = parseArticleHtml(widget.article.content);
    _checkSavedStatus();
  }

  Future<void> _checkSavedStatus() async {
    final saved = await BookmarksService.isBookmarked(widget.article.id.toString());
    if (mounted) setState(() => _isSaved = saved);
  }

  void _shareArticle() {
    final url = 'https://mjengohub.co.ke/news/${widget.article.slug}';
    SocialShareModal.show(context, title: 'Read this on Mjengo Hub: "${widget.article.title}"', url: url);
  }

  @override
  Widget build(BuildContext context) {
    // Interleave one "Explore Active Developments" card roughly halfway
    // through the body, plus one more at the very end — matches the spec's
    // "between content blocks and at the end of the article."
    final midpoint = (_blocks.length / 2).ceil();
    // Strict full-bleed 16:9 hero, sized off the viewport width so it holds
    // that ratio on every screen size rather than a fixed pixel height.
    final heroHeight = MediaQuery.of(context).size.width * 9 / 16;

    final hasCaption = widget.article.featuredImageCaption?.isNotEmpty == true;
    final hasCredit = widget.article.featuredImageCredit?.isNotEmpty == true;

    return CustomScrollView(
      controller: widget.scrollController,
      slivers: [
        SliverAppBar(
          expandedHeight: heroHeight,
          pinned: true,
          backgroundColor: Colors.black,
          elevation: 0,
          leading: _backButton(),
          actions: [_bookmarkButton(), _shareButton()],
          flexibleSpace: FlexibleSpaceBar(
            background: _HeroImage(article: widget.article),
            collapseMode: CollapseMode.parallax,
          ),
        ),

        // Caption + credit sit directly beneath the hero image with zero
        // large gap, before anything else in the header.
        if (hasCaption || hasCredit)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (hasCaption)
                    Text(
                      widget.article.featuredImageCaption!,
                      style: GoogleFonts.montserrat(fontSize: 12.5, color: const Color(0xFF64748B), fontStyle: FontStyle.italic, height: 1.4),
                    ),
                  if (hasCaption && hasCredit)
                    const Text('  ·  ', style: TextStyle(color: Color(0xFF64748B))),
                  if (hasCredit)
                    Text(
                      'Photo: ${widget.article.featuredImageCredit}',
                      style: GoogleFonts.montserrat(fontSize: 12.5, color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                    ),
                ],
              ),
            ),
          ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.article.category != null) ...[
                  _CategoryPill(name: widget.article.category!.name),
                  const SizedBox(height: 10),
                ],

                // Editorial header — full, un-truncated title.
                Text(
                  widget.article.title,
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: 1.28,
                  ),
                ),
                const SizedBox(height: 14),

                _AuthorBylineRow(article: widget.article, onShare: _shareArticle),
                const SizedBox(height: 20),

                const Divider(color: Color(0xFFF3F4F6), height: 1),
                const SizedBox(height: 20),

                if (widget.article.summary != null && widget.article.summary!.isNotEmpty) ...[
                  _SummaryCallout(text: widget.article.summary!),
                  const SizedBox(height: 24),
                ],
              ],
            ),
          ),
        ),

        // Rich body blocks, with a discovery card spliced in at the
        // midpoint.
        for (int i = 0; i < _blocks.length; i++) ...[
          if (i == midpoint)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  children: [
                    ReadAlsoCard(article: widget.article),
                    TaggedProjectCard(article: widget.article),
                    ArticleMapEmbed(article: widget.article),
                  ],
                ),
              ),
            ),
          if (i == midpoint) const SliverToBoxAdapter(child: RelatedTrackersCard()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: _ArticleBlockWidget(block: _blocks[i]),
            ),
          ),
        ],

        SliverToBoxAdapter(
          child: Column(
            children: [
              const SizedBox(height: 8),
              const RelatedTrackersCard(),
              const SizedBox(height: 24),
              ArticleDiscoverySection(article: widget.article),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                color: Colors.white,
                padding: const EdgeInsets.all(20),
                child: CommentsSection(
                  resource: CommentResource.article,
                  resourceId: widget.article.id,
                  title: 'Discussion',
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
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
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _bookmarkButton() {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8, right: 4),
      child: GestureDetector(
        onTap: () async {
          final nowSaved = await BookmarksService.toggleBookmark(
            BookmarkedItem(
              id: widget.article.id.toString(),
              title: widget.article.title,
              slug: widget.article.slug,
              imageUrl: widget.article.imageUrl,
              category: widget.article.category?.name,
              type: 'article',
              savedAt: DateTime.now(),
            ),
          );
          if (mounted) {
            setState(() => _isSaved = nowSaved);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(nowSaved ? 'Article saved to bookmarks' : 'Article removed from bookmarks'), duration: const Duration(seconds: 2)),
            );
          }
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(10)),
          child: Icon(
            _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
            color: _isSaved ? const Color(0xFFF59E0B) : Colors.white,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _shareButton() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 8, 12, 8),
      child: GestureDetector(
        onTap: _shareArticle,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), borderRadius: BorderRadius.circular(10)),
          child: const Icon(Icons.share_rounded, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

// -- Hero image ------------------------------------------------------------

class _HeroImage extends StatelessWidget {
  final Article article;
  const _HeroImage({required this.article});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        NetImage(url: article.imageUrl, fit: BoxFit.cover, placeholderColor: const Color(0xFF1F2937)),
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0x22000000), Color(0x66000000)],
              stops: [0.5, 1.0],
            ),
          ),
        ),
      ],
    );
  }
}

// -- Summary callout ---------------------------------------------------------
//
// The deck/summary is a distinct editorial callout, not body copy — light
// slate tint, 1px slate-200 border, plus a 3px deep-slate left accent bar.

class _SummaryCallout extends StatelessWidget {
  final String text;
  const _SummaryCallout({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        border: const Border(
          top: BorderSide(color: Color(0xFFE2E8F0)),
          right: BorderSide(color: Color(0xFFE2E8F0)),
          bottom: BorderSide(color: Color(0xFFE2E8F0)),
          left: BorderSide(color: Color(0xFF0F172A), width: 3),
        ),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: Text(
        text,
        style: GoogleFonts.montserrat(fontSize: 15, color: const Color(0xFF334155), height: 1.6, fontWeight: FontWeight.w500),
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  final String name;
  const _CategoryPill({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFFF97316), borderRadius: BorderRadius.circular(20)),
      child: Text(
        name.toUpperCase(),
        style: GoogleFonts.montserrat(fontSize: 10.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4),
      ),
    );
  }
}

// -- Author byline row -------------------------------------------------------
//
// Avatar, published date, read-time chip, and an inline share button. No
// Prime badge here — `is_prime` is a session-rendered-only field on the
// website (application.py), never exposed by `/api/v1` (`_article_dict` in
// api.py has no `is_prime` key), so the app has no real signal to show one
// on; fabricating it would be a lie the API can't back up.

class _AuthorBylineRow extends StatelessWidget {
  final Article article;
  final VoidCallback onShare;
  const _AuthorBylineRow({required this.article, required this.onShare});

  String _formattedDate() {
    if (article.publishedAt == null) return '';
    try {
      final d = DateTime.parse(article.publishedAt!).toLocal();
      const months = ['', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
      return '${months[d.month]} ${d.day}, ${d.year}';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final author = article.author;
    final date = _formattedDate();

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (author != null) ...[
          ClipOval(
            child: NetImage(url: author.imageUrl, width: 36, height: 36, fit: BoxFit.cover, placeholderColor: const Color(0xFF374151)),
          ),
          const SizedBox(width: 10),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (author != null)
                Text(author.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w700, color: const Color(0xFF111827))),
              Wrap(
                spacing: 6,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (date.isNotEmpty)
                    Text(date, style: GoogleFonts.montserrat(fontSize: 11.5, color: const Color(0xFF9CA3AF))),
                  if (date.isNotEmpty && article.readTime != null)
                    Text('•', style: GoogleFonts.montserrat(fontSize: 11.5, color: const Color(0xFF9CA3AF))),
                  if (article.readTime != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(color: const Color(0xFFF1F5F9), borderRadius: BorderRadius.circular(20)),
                      child: Text('${article.readTime} min read',
                          style: GoogleFonts.montserrat(fontSize: 10.5, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
                    ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: onShare,
          child: Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(color: const Color(0xFFF1F5F9), shape: BoxShape.circle),
            child: const Icon(Icons.ios_share_rounded, size: 15, color: Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }
}

// -- Rich body block renderer -------------------------------------------------

class _ArticleBlockWidget extends StatelessWidget {
  final ArticleContentBlock block;
  const _ArticleBlockWidget({required this.block});

  @override
  Widget build(BuildContext context) {
    switch (block.type) {
      case ArticleBlockType.heading2:
        return Padding(
          padding: const EdgeInsets.only(top: 24, bottom: 10),
          child: Text(block.text!,
              style: GoogleFonts.montserrat(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF0F172A), height: 1.3)),
        );
      case ArticleBlockType.heading3:
        return Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 8),
          child: Text(block.text!,
              style: GoogleFonts.montserrat(fontSize: 17, fontWeight: FontWeight.w700, color: const Color(0xFF0F172A), height: 1.3)),
        );
      case ArticleBlockType.quote:
        return Container(
          margin: const EdgeInsets.symmetric(vertical: 14),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          decoration: const BoxDecoration(
            color: Color(0xFFF8FAFC),
            border: Border(left: BorderSide(color: AppColors.accentBlue, width: 4)),
          ),
          child: Text(block.text!,
              style: GoogleFonts.montserrat(fontSize: 15, fontStyle: FontStyle.italic, color: const Color(0xFF334155), height: 1.6)),
        );
      case ArticleBlockType.bulletList:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: block.items!
                .map((item) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.accentBlue, shape: BoxShape.circle)),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item, style: GoogleFonts.montserrat(fontSize: 15, color: const Color(0xFF4B5563), height: 1.6)),
                          ),
                        ],
                      ),
                    ))
                .toList(),
          ),
        );
      case ArticleBlockType.image:
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: NetImage(url: block.imageUrl, fit: BoxFit.cover, width: double.infinity, placeholderColor: const Color(0xFF1F2937)),
              ),
              if (block.imageCaption?.isNotEmpty == true) ...[
                const SizedBox(height: 6),
                Text(block.imageCaption!,
                    style: GoogleFonts.montserrat(fontSize: 11.5, color: const Color(0xFF9CA3AF), fontStyle: FontStyle.italic)),
              ],
            ],
          ),
        );
      case ArticleBlockType.paragraph:
        final baseStyle = GoogleFonts.montserrat(fontSize: 15.5, color: const Color(0xFF334155), height: 1.75);
        if (block.spans == null) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(block.text!, style: baseStyle),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: Text.rich(
            TextSpan(
              children: block.spans!
                  .map((s) => s.href == null || s.href!.isEmpty
                      ? TextSpan(text: s.text, style: baseStyle)
                      : TextSpan(
                          text: s.text,
                          style: baseStyle.copyWith(color: AppColors.accentBlue, decoration: TextDecoration.underline),
                          recognizer: TapGestureRecognizer()..onTap = () => _openInlineLink(s.href!),
                        ))
                  .toList(),
            ),
          ),
        );
    }
  }

  /// Article-internal links (`mjengohub.co.ke/articles/<category>/<slug>` and
  /// the legacy `/article/<slug>` / `/news/<slug>` forms) navigate natively
  /// inside the app; anything else opens in the in-app browser, matching
  /// every other external link in this app.
  void _openInlineLink(String href) {
    final slug = _internalArticleSlug(href);
    if (slug != null) {
      Get.toNamed(AppRoutes.articleDetail, arguments: slug);
      return;
    }
    final uri = Uri.tryParse(href);
    if (uri == null) return;
    canLaunchUrl(uri).then((ok) {
      if (ok) launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    });
  }

  String? _internalArticleSlug(String href) {
    final uri = Uri.tryParse(href);
    if (uri == null) return null;
    final host = uri.host.toLowerCase();
    final isMjengoHost =
        host.isEmpty || host == 'mjengohub.co.ke' || host == 'www.mjengohub.co.ke' || host == 'app.mjengohub.co.ke';
    if (!isMjengoHost) return null;
    final segments = uri.pathSegments.where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return null;
    final head = segments.first.toLowerCase();
    if (head != 'articles' && head != 'article' && head != 'news') return null;
    return segments.last;
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
            const Icon(Icons.article_outlined, size: 52, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(message.isEmpty ? 'Article not found.' : message,
                textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 14, color: const Color(0xFF6B7280))),
            const SizedBox(height: 20),
            TextButton(
              onPressed: Get.back,
              child: Text('Go back', style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
