// lib/profile/screens/submissions_screen.dart
//
// "My Submissions" — a structured, tabbed view of the user's own content
// (articles, public/private projects, incidents, comments), reachable from
// the Profile screen.
//
// WARNING: verified against the live backend (api.py) — none of the list
// endpoints this would need (`GET articles`, `GET projects`, `GET incidents`)
// accept an author/user filter, and there is no per-user comments endpoint
// at all. The website's equivalent (`/profile` in application.py) queries
// these directly via an authenticated Flask session against SQLAlchemy, not
// through `/api/v1` JSON, and deliberately includes unpublished/pending rows
// (drafts, unapproved comments) that the public JSON endpoints filter out —
// so even client-side filtering of the public lists couldn't reproduce it.
// Each tab below shows an honest "not available yet" state instead of
// silently returning incomplete or wrong data. Wire real fetches here once
// api.py exposes user-scoped endpoints.
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/responsive.dart';

class SubmissionsScreen extends StatefulWidget {
  const SubmissionsScreen({super.key});

  @override
  State<SubmissionsScreen> createState() => _SubmissionsScreenState();
}

class _SubmissionsScreenState extends State<SubmissionsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  static const _tabs = [
    _SubmissionTab(
      label: 'Articles',
      icon: Icons.article_outlined,
      message: 'Articles and drafts you\'ve authored aren\'t available in the app yet.',
    ),
    _SubmissionTab(
      label: 'Public Projects',
      icon: Icons.corporate_fare_rounded,
      message: 'Infrastructure projects you\'ve submitted aren\'t available in the app yet.',
    ),
    _SubmissionTab(
      label: 'Private Projects',
      icon: Icons.apartment_rounded,
      message: 'Private developments you\'ve submitted aren\'t available in the app yet.',
    ),
    _SubmissionTab(
      label: 'Incidents',
      icon: Icons.report_gmailerrorred_rounded,
      message: 'Road safety and site safety incidents you\'ve reported aren\'t available in the app yet.',
    ),
    _SubmissionTab(
      label: 'Comments',
      icon: Icons.mode_comment_outlined,
      message: 'Your comments and discussions aren\'t available in the app yet.',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text(
          'My Submissions',
          style: GoogleFonts.montserrat(fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.textDark),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.accentBlue,
          unselectedLabelColor: AppColors.textSubtle,
          indicatorColor: AppColors.accentBlue,
          labelStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w600),
          unselectedLabelStyle: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: _tabs.map((t) => Tab(text: t.label)).toList(),
        ),
      ),
      body: ContentWidth(
        maxWidth: 700,
        child: TabBarView(
          controller: _tabController,
          children: _tabs
              .map((t) => ComingSoonPlaceholder(
                    icon: t.icon,
                    title: 'Not available yet',
                    message: t.message,
                  ))
              .toList(),
        ),
      ),
    );
  }
}

class _SubmissionTab {
  final String label;
  final IconData icon;
  final String message;
  const _SubmissionTab({required this.label, required this.icon, required this.message});
}
