// lib/news/screens/discover_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/discover_controller.dart';
import '../models/article_model.dart';
import '../widgets/article_list_tile.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';

class DiscoverScreen extends StatelessWidget {
  const DiscoverScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<DiscoverController>();

    return Container(
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),

          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'News and Articles',
                  style: GoogleFonts.montserrat(
                    fontSize: 26,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textDark,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Expert insights and analysis on Kenya's construction industry",
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSubtle,
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
              size: 20, color: Color(0xFF475569)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: ctrl.searchController,
              onSubmitted: ctrl.onSearchSubmit,
              textInputAction: TextInputAction.search,
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: const Color(0xFF111827)),
              decoration: InputDecoration(
                hintText: 'Search',
                hintStyle: GoogleFonts.montserrat(
                    fontSize: 14, color: const Color(0xFF475569)),
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
                            size: 18, color: Color(0xFF475569)),
                      ),
                    )
                  : const SizedBox(width: 8),
            ),
          Container(
            height: 30,
            width: 1,
            color: const Color(0xFFE5E7EB),
          ),
          Obx(() {
            final active = ctrl.selectedSlug.value.isNotEmpty;
            return GestureDetector(
              onTap: () => _showFilterSheet(context, ctrl),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Icon(Icons.tune_rounded,
                        size: 18,
                        color: active
                            ? AppColors.accentBlue
                            : const Color(0xFF374151)),
                    if (active)
                      Positioned(
                        top: -3,
                        right: -3,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppColors.accentBlue,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
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

// Filled pill chips, matching the website's `.ar-pill` category filter
// (templates/articles.html) rather than an underline-tab treatment.
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
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accentBlue : AppColors.background,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }
}

// ── Filter bottom sheet ───────────────────────────────────────────────────────

void _showFilterSheet(BuildContext context, DiscoverController ctrl) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => _FilterSheet(ctrl: ctrl),
  );
}

class _FilterSheet extends StatelessWidget {
  final DiscoverController ctrl;
  const _FilterSheet({required this.ctrl});

  static const _kPurple  = AppColors.accentBlue;
  static const _kDark    = Color(0xFF111827);
  static const _kSubtext = Color(0xFF475569);
  static const _kDivider = Color(0xFFF3F4F6);

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final maxHeight   = MediaQuery.of(context).size.height * 0.75;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Fixed header ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Title + Clear button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Filter by Category',
                          style: GoogleFonts.montserrat(
                              fontSize: 17,
                              fontWeight: FontWeight.w500,
                              color: _kDark)),
                      Obx(() => ctrl.selectedSlug.value.isNotEmpty
                          ? GestureDetector(
                              onTap: () {
                                ctrl.selectCategory('');
                                Navigator.pop(context);
                              },
                              child: Text('Clear',
                                  style: GoogleFonts.montserrat(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _kPurple)),
                            )
                          : const SizedBox.shrink()),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('Choose a topic to filter articles',
                      style: GoogleFonts.montserrat(
                          fontSize: 12.5, color: _kSubtext)),
                  const SizedBox(height: 16),
                  const Divider(color: _kDivider, height: 1),
                ],
              ),
            ),

            // ── Scrollable options list ─────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(24, 8, 24, bottomInset + 24),
                child: Obx(() {
                  final cats = ctrl.categories;
                  return Column(
                    children: [
                      // "All" option
                      _FilterOption(
                        label: 'All Categories',
                        icon: Icons.grid_view_rounded,
                        isSelected: ctrl.selectedSlug.value.isEmpty,
                        onTap: () {
                          ctrl.selectCategory('');
                          Navigator.pop(context);
                        },
                      ),

                      // Category options
                      if (cats.isEmpty)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text('No categories available',
                                style: GoogleFonts.montserrat(
                                    fontSize: 13, color: _kSubtext)),
                          ),
                        )
                      else
                        ...cats.map((cat) => _FilterOption(
                              label: cat.name,
                              icon: _categoryIcon(cat.slug),
                              isSelected:
                                  ctrl.selectedSlug.value == cat.slug,
                              onTap: () {
                                ctrl.selectCategory(cat.slug);
                                Navigator.pop(context);
                              },
                            )),
                    ],
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _categoryIcon(String slug) {
    final s = slug.toLowerCase();
    if (s.contains('infrastructure') || s.contains('transport')) {
      return Icons.account_balance_rounded;
    }
    if (s.contains('real') || s.contains('estate') || s.contains('property')) {
      return Icons.home_work_rounded;
    }
    if (s.contains('safety') || s.contains('regulation')) {
      return Icons.health_and_safety_rounded;
    }
    if (s.contains('material') || s.contains('technology')) {
      return Icons.science_rounded;
    }
    if (s.contains('urban') || s.contains('planning')) {
      return Icons.location_city_rounded;
    }
    if (s.contains('road') || s.contains('highway')) {
      return Icons.add_road_rounded;
    }
    if (s.contains('government') || s.contains('policy')) {
      return Icons.gavel_rounded;
    }
    return Icons.article_rounded;
  }
}

class _FilterOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterOption({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  static const _kPurple = AppColors.accentBlue;
  static const _kDark   = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? _kPurple.withValues(alpha: 0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? _kPurple : Colors.transparent,
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            Icon(icon,
                size: 18,
                color: isSelected ? _kPurple : const Color(0xFF475569)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight:
                      isSelected ? FontWeight.w500 : FontWeight.w500,
                  color: isSelected ? _kPurple : _kDark,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded,
                  size: 18, color: _kPurple),
          ],
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
            style: GoogleFonts.montserrat(
                fontSize: 14, color: const Color(0xFF475569)),
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
