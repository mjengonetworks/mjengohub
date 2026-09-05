// lib/incidents/screens/incidents_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../navigation/app_header.dart';
import '../../news/widgets/net_image.dart';
import '../controllers/incidents_controller.dart';
import '../models/incident_model.dart';
import 'incident_detail_screen.dart';
import 'report_incident_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — mirrors Videos / Discover screens
// ─────────────────────────────────────────────────────────────────────────────
const _kDark    = Color(0xFF111827);
const _kSubtext = Color(0xFF475569);
const _kBg      = Color(0xFFF3F4F6);
const _kDivider = Color(0xFFF3F4F6);

// ═════════════════════════════════════════════════════════════════════════════
//  ROOT SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class IncidentsListScreen extends StatelessWidget {
  final String incidentType;
  const IncidentsListScreen({Key? key, required this.incidentType})
      : super(key: key);

  bool get _isRoad => incidentType == 'road_safety';

  Color get _accent =>
      _isRoad ? const Color(0xFFDC2626) : const Color(0xFFF97316);

  String get _title =>
      _isRoad ? 'Share Barabara' : 'Site Safety';

  String get _subtitle =>
      _isRoad
          ? 'Learning from road accidents across Kenya'
          : 'Construction site incident database';

  @override
  Widget build(BuildContext context) {
    final tag  = 'incidents_$incidentType';
    final ctrl = Get.put(IncidentsController(incidentType), tag: tag);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Get.to(
            () => ReportIncidentScreen(incidentType: incidentType),
            transition: Transition.cupertino,
          ),
          backgroundColor: _accent,
          foregroundColor: Colors.white,
          elevation: 2,
          icon: const Icon(Icons.add_rounded, size: 20),
          label: Text(
            'Report Incident',
            style: GoogleFonts.montserrat(
                fontSize: 13, fontWeight: FontWeight.w700),
          ),
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AppHeader(),
            const SizedBox(height: 12),

            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + title on same row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: _kDark,
                              size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _title,
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _kDark,
                            ),
                          ),
                          Text(
                            _subtitle,
                            style: GoogleFonts.montserrat(
                                fontSize: 11, color: _kSubtext),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Search bar (matches Videos screen) ──────────────────
                  _SearchBar(ctrl: ctrl, accent: _accent),
                  const SizedBox(height: 4),
                ],
              ),
            ),

            // ── Severity tabs (underline style, matches Videos) ────────────
            _SeverityTabs(ctrl: ctrl, accent: _accent),

            // ── Crisis banner (road safety only) ───────────────────────────
            if (_isRoad) ...[
              const SizedBox(height: 8),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: _CrisisBanner(),
              ),
            ],

            // ── Content list ───────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(_kDark),
                    ),
                  );
                }
                // Snapshot RxList → plain List so child widgets
                // don't read reactive state outside Obx scope.
                final featured = ctrl.featuredIncidents.toList();
                final all      = ctrl.incidents.toList();
                return NotificationListener<ScrollNotification>(
                  onNotification: (n) {
                    if (n is ScrollEndNotification &&
                        n.metrics.pixels >=
                            n.metrics.maxScrollExtent - 200) {
                      ctrl.loadMore();
                    }
                    return false;
                  },
                  child: ListView(
                    padding: const EdgeInsets.only(top: 8, bottom: 100),
                    children: [
                      if (featured.isNotEmpty)
                        _FeaturedSection(
                            incidents: featured, accent: _accent),
                      _IncidentList(
                          incidents: all, accent: _accent),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SEARCH BAR  (identical style to Videos screen)
// ═════════════════════════════════════════════════════════════════════════════

class _SearchBar extends StatefulWidget {
  final IncidentsController ctrl;
  final Color accent;
  const _SearchBar({required this.ctrl, required this.accent});

  @override
  State<_SearchBar> createState() => _SearchBarState();
}

class _SearchBarState extends State<_SearchBar> {
  late final TextEditingController _textCtrl;

  @override
  void initState() {
    super.initState();
    _textCtrl = TextEditingController(
        text: widget.ctrl.searchQuery.value);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    widget.ctrl.applyFilters(q: _textCtrl.text.trim());
    FocusScope.of(context).unfocus();
  }

  void _clear() {
    _textCtrl.clear();
    widget.ctrl.applyFilters(q: '');
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 46,
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const SizedBox(width: 12),
          const Icon(Icons.search_rounded, size: 20, color: _kSubtext),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _textCtrl,
              onSubmitted: (_) => _submit(),
              textInputAction: TextInputAction.search,
              style: GoogleFonts.montserrat(fontSize: 14, color: _kDark),
              decoration: InputDecoration(
                hintText: 'Search incidents…',
                hintStyle: GoogleFonts.montserrat(
                    fontSize: 14, color: const Color(0xFF475569)),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
          // Clear button
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: _textCtrl,
            builder: (_, val, __) => val.text.isNotEmpty
                ? GestureDetector(
                    onTap: _clear,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 10),
                      child: Icon(Icons.close_rounded,
                          size: 18, color: _kSubtext),
                    ),
                  )
                : const SizedBox(width: 12),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SEVERITY TABS  (underline style — mirrors Videos _CategoryTabs)
// ═════════════════════════════════════════════════════════════════════════════

class _SeverityTabs extends StatelessWidget {
  final IncidentsController ctrl;
  final Color accent;
  const _SeverityTabs({required this.ctrl, required this.accent});

  static const _values = ['', 'minor', 'moderate', 'serious', 'fatal'];
  static const _labels = ['All', 'Minor', 'Moderate', 'Serious', 'Fatal'];

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // Snapshot here — inside Obx scope — so GetX tracks the dependency.
      // Never read .value inside a lazy builder callback.
      final selected = ctrl.selectedSeverity.value;
      return SizedBox(
        height: 42,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          itemCount: _values.length,
          itemBuilder: (_, i) => _TabItem(
            label: _labels[i],
            isSelected: selected == _values[i],
            onTap: () => ctrl.applyFilters(severity: _values[i]),
          ),
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
              color: isSelected ? _kDark : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(
            fontSize: 14,
            fontWeight:
                isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? _kDark : _kSubtext,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CRISIS BANNER
// ═════════════════════════════════════════════════════════════════════════════

class _CrisisBanner extends StatelessWidget {
  const _CrisisBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:+254722178177');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4E6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.phone_rounded,
                  color: Color(0xFFDC2626), size: 16),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crisis Support',
                    style: GoogleFonts.montserrat(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  Text(
                    'Befrienders Kenya · +254 722 178 177  |  999 / 112',
                    style: GoogleFonts.montserrat(
                        fontSize: 11.5, color: const Color(0xFF475569)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  FEATURED SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _FeaturedSection extends StatelessWidget {
  final List<Incident> incidents;
  final Color accent;
  const _FeaturedSection({required this.incidents, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Featured Incidents',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          // +18px vs. the old fixed-100 thumbnail to fit the true 16:9
          // height at this card's 210px width, without shrinking the text
          // area below it.
          height: 208,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: incidents.length,
            itemBuilder: (_, i) => _FeaturedCard(
              incident: incidents[i],
              accent: accent,
            ),
          ),
        ),
        const SizedBox(height: 20),
        const Divider(
            height: 1, indent: 20, endIndent: 20, color: _kDivider),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'All Incidents',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
        ),
        const SizedBox(height: 4),
      ],
    );
  }
}

class _FeaturedCard extends StatelessWidget {
  final Incident incident;
  final Color accent;
  const _FeaturedCard(
      {required this.incident, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => IncidentDetailScreen(slug: incident.slug),
        transition: Transition.cupertino,
      ),
      child: Container(
        width: 210,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _kDivider),
          boxShadow: const [
            BoxShadow(
                color: Color(0x06000000),
                blurRadius: 8,
                offset: Offset(0, 3))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(14)),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: NetImage(
                  url: incident.imageUrl,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  placeholderColor: _kBg,
                  placeholderIcon: incident.isRoadSafety
                      ? Icons.report_problem_rounded
                      : Icons.engineering_rounded,
                  placeholderIconColor: const Color(0xFFCCCCDD),
                  placeholderIconSize: 32,
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SeverityBadge(severity: incident.severity),
                    const SizedBox(height: 4),
                    Text(
                      incident.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: _kDark,
                        height: 1.3,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '📍 ${incident.county ?? incident.location ?? ''}',
                      style: GoogleFonts.montserrat(
                          fontSize: 10, color: _kSubtext),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ═════════════════════════════════════════════════════════════════════════════
//  INCIDENT LIST  (flat rows with dividers — mirrors VideoListTile)
// ═════════════════════════════════════════════════════════════════════════════

class _IncidentList extends StatelessWidget {
  final List<Incident> incidents;
  final Color accent;
  const _IncidentList({required this.incidents, required this.accent});

  @override
  Widget build(BuildContext context) {
    if (incidents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(32),
        child: Center(
          child: Text(
            'No incidents found.',
            style: GoogleFonts.montserrat(
                fontSize: 14, color: _kSubtext),
          ),
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      itemCount: incidents.length,
      separatorBuilder: (_, __) => const Divider(
          height: 1, indent: 20, endIndent: 20, color: _kDivider),
      itemBuilder: (_, i) =>
          _IncidentTile(incident: incidents[i], accent: accent),
    );
  }
}

class _IncidentTile extends StatelessWidget {
  final Incident incident;
  final Color accent;
  const _IncidentTile(
      {required this.incident, required this.accent});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(
        () => IncidentDetailScreen(slug: incident.slug),
        transition: Transition.cupertino,
      ),
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Thumbnail ────────────────────────────────────────────────
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: SizedBox(
                width: 72,
                height: 72,
                child: NetImage(
                  url: incident.imageUrl,
                  fit: BoxFit.cover,
                  placeholderColor: _kBg,
                  placeholderIcon: incident.isRoadSafety
                      ? Icons.report_problem_rounded
                      : Icons.engineering_rounded,
                  placeholderIconColor: const Color(0xFFCCCCDD),
                  placeholderIconSize: 26,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // ── Text ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Severity + date
                  Row(
                    children: [
                      _SeverityBadge(severity: incident.severity),
                      const Spacer(),
                      Text(
                        incident.formattedDate,
                        style: GoogleFonts.montserrat(
                            fontSize: 11, color: _kSubtext),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // Title
                  Text(
                    incident.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      color: _kDark,
                      height: 1.3,
                    ),
                  ),

                  // Location
                  if (incident.county != null ||
                      incident.location != null) ...[
                    const SizedBox(height: 3),
                    Text(
                      '📍 ${incident.county ?? incident.location}',
                      style: GoogleFonts.montserrat(
                          fontSize: 11.5, color: _kSubtext),
                    ),
                  ],

                  // Stat chips
                  if (incident.casualties != null ||
                      incident.injuries != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        if (incident.casualties != null)
                          _StatChip(
                            label:
                                '${incident.casualties} fatalities',
                            color: const Color(0xFFDC2626),
                          ),
                        if (incident.injuries != null) ...[
                          const SizedBox(width: 6),
                          _StatChip(
                            label: '${incident.injuries} injured',
                            color: const Color(0xFFF97316),
                          ),
                        ],
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ═════════════════════════════════════════════════════════════════════════════
//  SHARED SMALL WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _SeverityBadge extends StatelessWidget {
  final String severity;
  const _SeverityBadge({required this.severity});

  Color get _color {
    switch (severity) {
      case 'fatal':    return const Color(0xFF7F1D1D);
      case 'serious':  return const Color(0xFFDC2626);
      case 'moderate': return const Color(0xFFF97316);
      case 'minor':    return const Color(0xFF22C55E);
      default:         return _kSubtext;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: _color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        severity.toUpperCase(),
        style: GoogleFonts.montserrat(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Colors.white,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final Color color;
  const _StatChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
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
  }
}
