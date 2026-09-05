// lib/projects/screens/tracker_filtered_list_screen.dart
//
// Generic "View More" destination for the three tracker dynamic sections
// (Browse by Category, Most Viewed, By Status) — one screen, parameterized
// by a fetch callback, rather than three near-identical screens.
import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/responsive.dart';
import '../models/project_model.dart';
import '../widgets/tracker_project_card.dart';

class TrackerFilteredListScreen extends StatefulWidget {
  final String title;
  final Future<List<Project>> Function() fetcher;
  final String Function(Project)? captionOf;

  const TrackerFilteredListScreen({super.key, required this.title, required this.fetcher, this.captionOf});

  @override
  State<TrackerFilteredListScreen> createState() => _TrackerFilteredListScreenState();
}

class _TrackerFilteredListScreenState extends State<TrackerFilteredListScreen> {
  late Future<List<Project>> _future = widget.fetcher();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.textDark)),
      ),
      body: ContentWidth(
        maxWidth: 900,
        child: FutureBuilder<List<Project>>(
          future: _future,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final items = snap.data!;
            if (items.isEmpty) {
              return const ComingSoonPlaceholder(icon: Icons.folder_off_rounded, title: 'Nothing here yet', message: 'No projects match this filter.');
            }
            return RefreshIndicator(
              onRefresh: () async {
                setState(() => _future = widget.fetcher());
                await _future;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: items
                      .map((p) => TrackerProjectCard(project: p, captionOverride: widget.captionOf?.call(p), width: 220))
                      .toList(),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
