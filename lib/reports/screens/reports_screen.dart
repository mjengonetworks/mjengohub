// lib/reports/screens/reports_screen.dart
//
// Infrastructure reports list — the app-side of the website's
// "Report Infrastructure" feature (templates/infrastructure_reports.html).
// Supports category/severity filtering, up/down voting, and submitting a new
// report. Distinct from `lib/incidents/`, which covers safety *incidents*.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/responsive.dart';
import '../models/report_model.dart';
import '../services/reports_service.dart';

/// Severity -> chip colour, mirroring the website's badge palette.
const Map<String, Color> kSeverityColors = {
  'low': AppColors.success,
  'medium': AppColors.warning,
  'high': Color(0xFFEA580C),
  'critical': AppColors.danger,
};

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  final _api = ReportsService();

  List<InfrastructureReport> _reports = const [];
  bool _loading = true;
  String? _category;
  String? _severity;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final res = await _api.getReports(
      perPage: 30,
      category: _category,
      severity: _severity,
    );
    if (!mounted) return;
    setState(() {
      _reports = res.items;
      _loading = false;
    });
  }

  Future<void> _vote(InfrastructureReport r, bool up) async {
    final counts = await _api.voteReport(r.id, up: up);
    if (counts == null || !mounted) return;
    setState(() {
      _reports = _reports
          .map((e) => e.id == r.id
              ? e.copyWith(upvotes: counts.upvotes, downvotes: counts.downvotes)
              : e)
          .toList();
    });
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
          'Infrastructure Reports',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryBlue,
        onPressed: () async {
          final submitted = await Get.toNamed(AppRoutes.submitReport);
          if (submitted == true) _load();
        },
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Report',
          style: GoogleFonts.montserrat(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ),
      body: Column(
        children: [
          _filters(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _load,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _reports.isEmpty
                      ? _empty()
                      : ContentWidth(
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 12, 16, 90),
                            itemCount: _reports.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) => _ReportCard(
                              report: _reports[i],
                              onVote: (up) => _vote(_reports[i], up),
                            ),
                          ),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filters() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            _chip('All', _category == null && _severity == null, () {
              setState(() {
                _category = null;
                _severity = null;
              });
              _load();
            }),
            ...kReportSeverities.map(
              (s) => _chip(_titleCase(s), _severity == s, () {
                setState(() => _severity = _severity == s ? null : s);
                _load();
              }),
            ),
            ...kReportCategories.map(
              (c) => _chip(_titleCase(c), _category == c, () {
                setState(() => _category = _category == c ? null : c);
                _load();
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool active, VoidCallback onTap) => Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: active ? AppColors.primaryBlue : Colors.white,
              borderRadius: BorderRadius.circular(AppRadius.pill),
              border: Border.all(
                color: active ? AppColors.primaryBlue : AppColors.divider,
              ),
            ),
            child: Text(
              label,
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textSubtle,
              ),
            ),
          ),
        ),
      );

  Widget _empty() => ListView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 80),
        children: [
          const Icon(Icons.report_gmailerrorred_outlined,
              size: 44, color: AppColors.textSubtle),
          const SizedBox(height: 14),
          Text(
            'No reports match this filter',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textDark,
            ),
          ),
        ],
      );
}

String _titleCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

class _ReportCard extends StatelessWidget {
  const _ReportCard({required this.report, required this.onVote});

  final InfrastructureReport report;
  final ValueChanged<bool> onVote;

  @override
  Widget build(BuildContext context) {
    final sevColor = kSeverityColors[report.severity] ?? AppColors.textSubtle;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.card),
      onTap: () => Get.toNamed(AppRoutes.reportDetail, arguments: report.id),
      child: Container(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sevColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    _titleCase(report.severity),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: sevColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.divider,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    _titleCase(report.category),
                    style: GoogleFonts.montserrat(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ),
                const Spacer(),
                if (report.isVerified)
                  const Icon(Icons.verified, size: 15, color: AppColors.primaryBlue),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              report.title,
              style: GoogleFonts.montserrat(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                height: 1.35,
                color: AppColors.textDark,
              ),
            ),
            if (report.location != null && report.location!.isNotEmpty) ...[
              const SizedBox(height: 5),
              Row(
                children: [
                  const Icon(Icons.place_outlined, size: 13, color: AppColors.textSubtle),
                  const SizedBox(width: 3),
                  Expanded(
                    child: Text(
                      report.location!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                _voteButton(
                  icon: Icons.thumb_up_outlined,
                  count: report.upvotes,
                  onTap: () => onVote(true),
                ),
                const SizedBox(width: 14),
                _voteButton(
                  icon: Icons.thumb_down_outlined,
                  count: report.downvotes,
                  onTap: () => onVote(false),
                ),
                const Spacer(),
                Text(
                  '${report.viewCount} views',
                  style: GoogleFonts.montserrat(
                    fontSize: 11,
                    color: AppColors.textSubtle,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _voteButton({
    required IconData icon,
    required int count,
    required VoidCallback onTap,
  }) =>
      GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.textSubtle),
            const SizedBox(width: 4),
            Text(
              '$count',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.textSubtle,
              ),
            ),
          ],
        ),
      );
}
