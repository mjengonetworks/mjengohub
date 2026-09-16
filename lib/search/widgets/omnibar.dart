// lib/search/widgets/omnibar.dart
//
// Global AI-augmented search modal — distinct from the full-page
// SearchScreen (which hits the confirmed-live `GET /search` covering
// articles/services/reports). The Omnibar targets `GET ai-search`, which is
// not confirmed live (see ai_search_models.dart); it still ships fully
// wired so it lights up the moment the backend adds the route, degrading to
// a clear "not available yet" empty state until then, same as
// MjengoAuthController's `auth/google` handling.
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../models/ai_search_models.dart';
import '../services/search_service.dart';

const _kDebounce = Duration(milliseconds: 250);

const _starterChips = [
  'Nairobi Expressway',
  'KeNHA tenders & roads',
  'Affordable Housing Programme',
  'NCA compliance guides',
];

/// Opens the Omnibar as a near-fullscreen modal sheet with an autofocus
/// search field.
void showAiSearchSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => const _OmnibarSheet(),
  );
}

class _OmnibarSheet extends StatefulWidget {
  const _OmnibarSheet();

  @override
  State<_OmnibarSheet> createState() => _OmnibarSheetState();
}

class _OmnibarSheetState extends State<_OmnibarSheet> {
  final _service = SearchService();
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  Timer? _debounce;

  String _query = '';
  bool _loading = false;
  AISearchResponse? _result;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() => _query = value);
    if (value.trim().length < kMinSearchLength) {
      setState(() {
        _result = null;
        _loading = false;
      });
      return;
    }
    setState(() => _loading = true);
    _debounce = Timer(_kDebounce, () => _run(value));
  }

  Future<void> _run(String value) async {
    final result = await _service.fetchAISearch(value);
    if (!mounted || value != _controller.text) return;
    setState(() {
      _result = result;
      _loading = false;
    });
  }

  void _runChip(String value) {
    _controller.text = value;
    _controller.selection = TextSelection.collapsed(offset: value.length);
    _onChanged(value);
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final topPadding = MediaQuery.paddingOf(context).top;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColorsDark.surface : AppColors.surface;
    final fieldFill = isDark ? AppColorsDark.card : AppColors.mutedCanvas;
    final divider = isDark ? AppColorsDark.border : AppColors.divider;
    final textColor = isDark ? AppColorsDark.headingText : AppColors.textDark;
    final captionColor = isDark
        ? AppColorsDark.secondaryText
        : AppColors.captionSlate;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 150),
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: Container(
        height: MediaQuery.sizeOf(context).height - topPadding - 24,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 18,
                    color: AppColors.accentBlue,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Ask Mjengo AI',
                    style: GoogleFonts.montserrat(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: textColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                decoration: BoxDecoration(
                  color: fieldFill,
                  borderRadius: BorderRadius.circular(AppRadius.chip),
                  border: Border.all(color: divider),
                ),
                child: TextField(
                  controller: _controller,
                  focusNode: _focusNode,
                  autofocus: true,
                  onChanged: _onChanged,
                  style: GoogleFonts.montserrat(fontSize: 14, color: textColor),
                  decoration: InputDecoration(
                    hintText:
                        'Search projects, contractors, agencies, or articles...',
                    hintStyle: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: captionColor,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: captionColor,
                      size: 20,
                    ),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              Icons.close_rounded,
                              size: 18,
                              color: captionColor,
                            ),
                            onPressed: () => _onChanged(
                              (_controller..clear()).text,
                            ),
                          ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _query.trim().length < kMinSearchLength
                  ? _EmptyState(onChipTap: _runChip)
                  : _ResultsView(loading: _loading, result: _result),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  final ValueChanged<String> onChipTap;
  const _EmptyState({required this.onChipTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        Text(
          'Try asking',
          style: GoogleFonts.montserrat(
            fontSize: 12.5,
            fontWeight: FontWeight.w600,
            color: AppColors.captionSlate,
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _starterChips.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (context, i) {
              final chip = _starterChips[i];
              return ActionChip(
                label: Text(
                  chip,
                  style: GoogleFonts.montserrat(fontSize: 12.5),
                ),
                backgroundColor: AppColors.mutedCanvas,
                side: const BorderSide(color: AppColors.divider),
                onPressed: () => onChipTap(chip),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ResultsView extends StatelessWidget {
  final bool loading;
  final AISearchResponse? result;
  const _ResultsView({required this.loading, required this.result});

  @override
  Widget build(BuildContext context) {
    if (loading && result == null) {
      return const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }
    final res = result;
    if (res == null) return const SizedBox.shrink();
    if (res.isEmpty) {
      return _NoResults(query: res.query);
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        if (res.aiSummary != null) ...[
          _AiAnswerCard(summary: res.aiSummary!),
          const SizedBox(height: 18),
        ],
        for (final category in res.categories)
          if (category.items.isNotEmpty)
            _CategorySection(category: category),
      ],
    );
  }
}

class _NoResults extends StatelessWidget {
  final String query;
  const _NoResults({required this.query});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.search_off_rounded,
              size: 34,
              color: AppColors.captionSlate,
            ),
            const SizedBox(height: 10),
            Text(
              'No AI results for "$query" yet',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Try the regular search from the Discover tab, or rephrase your question.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                fontSize: 11.5,
                color: AppColors.captionSlate,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AiAnswerCard extends StatelessWidget {
  final String summary;
  const _AiAnswerCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F2E4D), Color(0xFF0284C7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome_rounded,
                size: 16,
                color: Colors.white,
              ),
              const SizedBox(width: 6),
              Text(
                'Mjengo AI Answer',
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            summary,
            style: GoogleFonts.montserrat(
              fontSize: 13.5,
              height: 1.45,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CategorySection extends StatelessWidget {
  final AISearchCategory category;
  const _CategorySection({required this.category});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            category.label,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
          const SizedBox(height: 8),
          for (final item in category.items) ...[
            _ResultTile(sectionLabel: category.label, item: item),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  final String sectionLabel;
  final AISearchResultItem item;
  const _ResultTile({required this.sectionLabel, required this.item});

  /// Routes by [AISearchResultItem.type] first ('project'/'article'/
  /// 'agency'/'entity') when the backend sends one; falls back to inferring
  /// from [sectionLabel] otherwise — "Guides & Insights" rows are always
  /// articles, "Projects & Agencies" rows default to a project (the more
  /// common row there) unless [type] says 'agency'/'entity'.
  void _open() {
    final slug = item.slug;
    if (slug == null || slug.isEmpty) return;
    final isGuide = sectionLabel == 'Guides & Insights';
    final type = item.type;
    if (type == 'article' || (type == null && isGuide)) {
      Get.toNamed(AppRoutes.articleDetail, arguments: slug);
    } else if (type == 'agency' || type == 'entity') {
      Get.toNamed(
        AppRoutes.entityProfile,
        arguments: {'slug': slug, 'fallbackName': item.title},
      );
    } else {
      Get.toNamed(AppRoutes.projectDetail, arguments: slug);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _open,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.chip),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: NetImage(
                url: item.imageUrl,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
                placeholderColor: AppColors.mutedCanvas,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textDark,
                    ),
                  ),
                  if (item.subtitle != null || item.county != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (item.subtitle != null)
                          Flexible(
                            child: Text(
                              item.subtitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 11,
                                color: AppColors.captionSlate,
                              ),
                            ),
                          ),
                        if (item.county != null) ...[
                          if (item.subtitle != null) const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.mutedCanvas,
                              borderRadius: BorderRadius.circular(
                                AppRadius.pill,
                              ),
                            ),
                            child: Text(
                              item.county!,
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: AppColors.accentBlue,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: AppColors.captionSlate,
            ),
          ],
        ),
      ),
    );
  }
}
