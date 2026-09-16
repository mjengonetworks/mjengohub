// lib/projects/screens/tracker_filtered_list_screen.dart
//
// Generic "View More" destination for the three tracker dynamic sections
// (Browse by Category, Most Viewed, By Status) and the Search screen's
// per-category "View More"/"View All" actions — one screen, parameterized
// by a page-aware fetch callback, rather than several near-identical
// screens.
//
// Pagination: [fetcher] is called with an incrementing page number; results
// are appended to the existing list (never replacing it), and a short page
// (fewer than [perPage] items) marks the end of the list. Scrolling near the
// bottom triggers the next page automatically.
import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/responsive.dart';
import '../models/project_model.dart';
import '../widgets/tracker_project_card.dart';

class TrackerFilteredListScreen extends StatefulWidget {
  final String title;
  final Future<List<Project>> Function(int page) fetcher;
  final String Function(Project)? captionOf;
  final int perPage;

  const TrackerFilteredListScreen({
    super.key,
    required this.title,
    required this.fetcher,
    this.captionOf,
    this.perPage = 20,
  });

  @override
  State<TrackerFilteredListScreen> createState() =>
      _TrackerFilteredListScreenState();
}

class _TrackerFilteredListScreenState extends State<TrackerFilteredListScreen> {
  final _scrollController = ScrollController();
  final List<Project> _items = [];
  int _page = 1;
  bool _initialLoading = true;
  bool _loadingMore = false;
  bool _hasMore = true;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadFirstPage();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_hasMore || _loadingMore || _initialLoading) return;
    final threshold = _scrollController.position.maxScrollExtent - 300;
    if (_scrollController.position.pixels >= threshold) _loadMore();
  }

  Future<void> _loadFirstPage() async {
    setState(() {
      _initialLoading = true;
      _page = 1;
      _hasMore = true;
    });
    final result = await widget.fetcher(1);
    if (!mounted) return;
    setState(() {
      _items
        ..clear()
        ..addAll(result);
      _hasMore = result.length >= widget.perPage;
      _initialLoading = false;
    });
  }

  Future<void> _loadMore() async {
    setState(() => _loadingMore = true);
    final nextPage = _page + 1;
    final result = await widget.fetcher(nextPage);
    if (!mounted) return;
    setState(() {
      _items.addAll(result);
      _page = nextPage;
      _hasMore = result.length >= widget.perPage;
      _loadingMore = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 16,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: ContentWidth(maxWidth: 900, child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_initialLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_items.isEmpty) {
      return const ComingSoonPlaceholder(
        icon: Icons.folder_off_rounded,
        title: 'Nothing here yet',
        message: 'No projects match this filter.',
      );
    }
    return RefreshIndicator(
      onRefresh: _loadFirstPage,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _items
                  .map(
                    (p) => TrackerProjectCard(
                      project: p,
                      captionOverride: widget.captionOf?.call(p),
                      width: 220,
                    ),
                  )
                  .toList(),
            ),
            if (_loadingMore)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
