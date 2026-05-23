// lib/news/screens/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/discover_controller.dart';
import '../models/article_model.dart';
import '../widgets/article_list_tile.dart';
import '../../point/routes/app_routes.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DiscoverController>();
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: topPad + 12),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Menu icon row
                Row(
                  children: [
                    Icon(Icons.menu_rounded,
                        size: 26, color: const Color(0xFF111827)),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Discover',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'News from all over the world',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 16),

                // ── Search bar ─────────────────────────────────────────
                _SearchBar(ctrl: ctrl),
                const SizedBox(height: 18),
              ],
            ),
          ),

          // ── Category tabs ─────────────────────────────────────────────
          _CategoryTabs(ctrl: ctrl),
          const SizedBox(height: 8),

          // ── Article list ──────────────────────────────────────────────
          Expanded(child: _ArticleList(ctrl: ctrl)),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  final DiscoverController ctrl;
  const _SearchBar({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded,
              size: 20, color: Color(0xFF9CA3AF)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl.searchController,
              onSubmitted: ctrl.onSearchSubmit,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.inter(
                  fontSize: 14, color: const Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.inter(
                    fontSize: 14, color: const Color(0xFFADB5BD)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          ValueListenableBuilder<TextEditingValue>(
              valueListenable: ctrl.searchController,
              builder: (_, val, __) => val.text.isNotEmpty
                  ? GestureDetector(
                      onTap: ctrl.clearSearch,
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10),
                        child: Icon(Icons.close_rounded,
                            size: 18, color: Color(0xFF9CA3AF)),
                      ),
                    )
                  : const SizedBox(width: 8),
            ),
          Container(
            height: 30,
            width: 1,
            color: const Color(0xFFE5E7EB),
          ),
          IconButton(
            icon: const Icon(Icons.tune_rounded,
                size: 18, color: Color(0xFF374151)),
            onPressed: () {},
            padding: const EdgeInsets.symmetric(horizontal: 12),
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ── Category tabs ─────────────────────────────────────────────────────────────

class _CategoryTabs extends StatelessWidget {
  final DiscoverController ctrl;
  const _CategoryTabs({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // "All" + actual categories from API
      final allLabel = _TabItem(
        label: 'All',
        isSelected: ctrl.selectedSlug.value.isEmpty,
        onTap: () => ctrl.selectCategory(''),
      );

      final catItems = ctrl.categories.map((cat) {
        final selected = ctrl.selectedSlug.value == cat.slug;
        return _TabItem(
          label: cat.name,
          isSelected: selected,
          onTap: () => ctrl.selectCategory(cat.slug),
        );
      }).toList();

      return SizedBox(
        height: 42,
        child: ListView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          children: [allLabel, ...catItems],
        ),
      );
    });
  }
}

class _TabItem extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabItem(
      {required this.label,
      required this.isSelected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 24),
        padding: const EdgeInsets.only(bottom: 6),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected
                  ? const Color(0xFF111827)
                  : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected
                ? const Color(0xFF111827)
                : const Color(0xFF9CA3AF),
          ),
        ),
      ),
    );
  }
}

// ── Article list ──────────────────────────────────────────────────────────────

class _ArticleList extends StatelessWidget {
  final DiscoverController ctrl;
  const _ArticleList({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (ctrl.isLoadingArticles.value && ctrl.articles.isEmpty) {
        return const Center(
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor:
                AlwaysStoppedAnimation<Color>(Color(0xFF111827)),
          ),
        );
      }

      if (ctrl.articles.isEmpty) {
        return Center(
          child: Text(
            'No articles found.',
            style: GoogleFonts.inter(
                fontSize: 14, color: const Color(0xFF9CA3AF)),
          ),
        );
      }

      return RefreshIndicator(
        color: const Color(0xFF111827),
        onRefresh: ctrl.refresh,
        child: ListView.separated(
          padding: const EdgeInsets.only(top: 4, bottom: 16),
          itemCount:
              ctrl.articles.length + (ctrl.hasMore.value ? 1 : 0),
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            indent: 20,
            endIndent: 20,
            color: Color(0xFFF3F4F6),
          ),
          itemBuilder: (_, i) {
            if (i == ctrl.articles.length) {
              // Load more trigger
              ctrl.fetchArticles();
              return const Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                          Color(0xFF111827))),
                ),
              );
            }
            final article = ctrl.articles[i];
            return ArticleListTile(
              article: article,
              onTap: () => _openArticle(article),
            );
          },
        ),
      );
    });
  }

  void _openArticle(Article article) {
    Get.toNamed(AppRoutes.articleDetail, arguments: article.slug);
  }
}
