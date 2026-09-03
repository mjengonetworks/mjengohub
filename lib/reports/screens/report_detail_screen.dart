// lib/reports/screens/report_detail_screen.dart
//
// Single infrastructure report. Fetching the detail also bumps the server-side
// view counter, so this screen intentionally always hits the network rather
// than reusing the list item it was opened from.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/responsive.dart';
import '../models/report_model.dart';
import '../services/reports_service.dart';
import 'reports_screen.dart' show kSeverityColors;

class ReportDetailScreen extends StatefulWidget {
  const ReportDetailScreen({super.key, this.reportId});

  final int? reportId;

  @override
  State<ReportDetailScreen> createState() => _ReportDetailScreenState();
}

class _ReportDetailScreenState extends State<ReportDetailScreen> {
  final _api = ReportsService();

  InfrastructureReport? _report;
  bool _loading = true;

  int get _id => widget.reportId ?? (Get.arguments is int ? Get.arguments as int : 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final r = _id == 0 ? null : await _api.getReport(_id);
    if (!mounted) return;
    setState(() {
      _report = r;
      _loading = false;
    });
  }

  Future<void> _vote(bool up) async {
    final counts = await _api.voteReport(_id, up: up);
    if (counts == null || !mounted || _report == null) return;
    setState(() {
      _report = _report!.copyWith(
        upvotes: counts.upvotes,
        downvotes: counts.downvotes,
      );
    });
  }

  String _titleCase(String s) => s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  Widget _tag(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.chip),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      );

  Widget _voteChip(IconData icon, int count, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.divider),
          ),
          child: Row(
            children: [
              Icon(icon, size: 15, color: AppColors.textSubtle),
              const SizedBox(width: 5),
              Text(
                '$count',
                style: GoogleFonts.montserrat(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
            ],
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final r = _report;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        title: Text(
          'Report',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : r == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'This report could not be loaded.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ),
                )
              : ContentWidth(child: _body(r)),
    );
  }

  Widget _body(InfrastructureReport r) => ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _tag(_titleCase(r.severity),
                  kSeverityColors[r.severity] ?? AppColors.textSubtle),
              _tag(_titleCase(r.category), AppColors.textSubtle),
              _tag(_titleCase(r.status.replaceAll('_', ' ')), AppColors.primaryBlue),
              if (r.isVerified) _tag('Verified', AppColors.success),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            r.title,
            style: GoogleFonts.montserrat(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              height: 1.3,
              color: AppColors.textDark,
            ),
          ),
          if (r.location != null && r.location!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.place_outlined, size: 15, color: AppColors.textSubtle),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    r.location!,
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      color: AppColors.textSubtle,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (r.description != null && r.description!.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              r.description!,
              style: GoogleFonts.montserrat(
                fontSize: 14,
                height: 1.65,
                color: AppColors.textDark,
              ),
            ),
          ],
          if (r.reporterName != null && r.reporterName!.isNotEmpty || r.timeAgo.isNotEmpty) ...[
            const SizedBox(height: 18),
            Text(
              [
                if (r.reporterName != null && r.reporterName!.isNotEmpty) 'Reported by ${r.reporterName}',
                if (r.timeAgo.isNotEmpty) r.timeAgo,
              ].join(' · '),
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: AppColors.textSubtle,
              ),
            ),
          ],
          const SizedBox(height: 24),
          Row(
            children: [
              _voteChip(Icons.thumb_up_outlined, r.upvotes, () => _vote(true)),
              const SizedBox(width: 10),
              _voteChip(Icons.thumb_down_outlined, r.downvotes, () => _vote(false)),
              const Spacer(),
              Text(
                '${r.viewCount} views',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textSubtle,
                ),
              ),
            ],
          ),
        ],
      );
}
