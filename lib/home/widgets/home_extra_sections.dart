// lib/home/widgets/home_extra_sections.dart
//
// New homepage sections for web/app parity: "Featured Articles & Analysis"
// (title-only), "Browse Projects by Category" (mixed public/private grid),
// and "Follow Mjengo Hub" (Mjengo Networks preview + social cluster).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../incidents/models/incident_model.dart';
import '../../incidents/screens/incident_detail_screen.dart';
import '../../incidents/services/incidents_service.dart';
import '../../news/models/article_model.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/projects_service.dart';
import '../../shared/services/demo_seed_data.dart';
import '../../shared/services/site_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/preview_data_badge.dart';

Future<void> _launchExternal(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

// ── Section header (shared look across the three sections) ──────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;

  /// True when the section below is showing fallback/demo data because the
  /// live API returned nothing (network failure, host firewall 403, etc.).
  final bool isDemo;

  const _SectionHeader({required this.title, this.onSeeAll, this.isDemo = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(title,
                  style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
              if (isDemo) const Padding(padding: EdgeInsets.only(left: 8), child: PreviewDataBadge()),
            ],
          ),
          if (onSeeAll != null)
            GestureDetector(
              onTap: onSeeAll,
              child: Text('See All',
                  style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280))),
            ),
        ],
      ),
    );
  }
}

// ── Featured Articles & Analysis (title-only, exactly 3) ─────────────────────

class FeaturedArticlesAnalysisSection extends StatelessWidget {
  final List<Article> articles;
  final void Function(Article) onOpen;
  final VoidCallback onSeeAll;

  const FeaturedArticlesAnalysisSection({
    super.key,
    required this.articles,
    required this.onOpen,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    if (articles.isEmpty) return const SizedBox.shrink();
    final items = articles.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Featured Articles & Analysis', onSeeAll: onSeeAll),
        const SizedBox(height: 10),
        for (int i = 0; i < items.length; i++) ...[
          GestureDetector(
            onTap: () => onOpen(items[i]),
            behavior: HitTestBehavior.opaque,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.accentBlue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(7),
                    ),
                    child: Text('${i + 1}',
                        style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppColors.accentBlue)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      items[i].title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.textDark, height: 1.35),
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.textSubtle),
                ],
              ),
            ),
          ),
          if (i != items.length - 1)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Divider(height: 1, color: AppColors.divider),
            ),
        ],
      ],
    );
  }
}

// ── Browse Projects by Category (mixed public/private grid) ─────────────────

class BrowseProjectsByCategorySection extends StatefulWidget {
  const BrowseProjectsByCategorySection({super.key});

  @override
  State<BrowseProjectsByCategorySection> createState() => _BrowseProjectsByCategorySectionState();
}

class _BrowseProjectsByCategorySectionState extends State<BrowseProjectsByCategorySection> {
  final _service = ProjectsService();
  List<Project> _projects = [];
  bool _loading = true;
  bool _isDemo = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _service.getPublicProjects(featured: true, perPage: 4),
      _service.getPrivateProjects(featured: true, perPage: 4),
    ]);
    final merged = <Project>[...results[0], ...results[1]]..shuffle();
    if (!mounted) return;
    if (merged.isEmpty) {
      setState(() {
        _projects = demoProjects();
        _isDemo = true;
        _loading = false;
      });
      return;
    }
    setState(() {
      _projects = merged.take(4).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _projects.isEmpty) return const SizedBox.shrink();
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width >= 700 ? 4 : 2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Browse Projects by Category',
          onSeeAll: () => Get.toNamed(AppRoutes.projects),
          isDemo: _isDemo,
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _loading
              ? GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: crossAxisCount * (crossAxisCount == 2 ? 2 : 1),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (_, __) => Container(
                    decoration: BoxDecoration(color: AppColors.divider, borderRadius: BorderRadius.circular(14)),
                  ),
                )
              : GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _projects.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.95,
                  ),
                  itemBuilder: (_, i) => _ProjectCategoryCard(project: _projects[i]),
                ),
        ),
      ],
    );
  }
}

class _ProjectCategoryCard extends StatelessWidget {
  final Project project;
  const _ProjectCategoryCard({required this.project});

  @override
  Widget build(BuildContext context) {
    final isPrivate = project.isPrivateProject;
    return GestureDetector(
      onTap: () => Get.to(() => ProjectDetailScreen(slug: project.slug), transition: Transition.cupertino),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                    url: project.imageUrl,
                    fit: BoxFit.cover,
                    placeholderColor: const Color(0xFF1E3A5F),
                    placeholderIcon: Icons.corporate_fare_rounded,
                  ),
                  Positioned(
                    top: 6,
                    left: 6,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: isPrivate ? AppColors.primeBadge : AppColors.accentBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        isPrivate ? 'PRIVATE' : 'PUBLIC',
                        style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.4),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Text(
                project.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Follow Mjengo Hub (Mjengo Networks card + social cluster) ───────────────

class FollowMjengoHubSection extends StatefulWidget {
  const FollowMjengoHubSection({super.key});

  @override
  State<FollowMjengoHubSection> createState() => _FollowMjengoHubSectionState();
}

class _FollowMjengoHubSectionState extends State<FollowMjengoHubSection> {
  static const String _mjengoNetworksUrl = 'https://mjengonetworks.co.ke/';

  // Fallback-only placeholders, used solely if the backend's admin-managed
  // SocialLink table (`/api/v1/site/social-links`) has no active rows yet.
  static const List<SocialLinkInfo> _fallbackLinks = [
    SocialLinkInfo(platform: 'youtube', url: 'https://youtube.com/@mjengohub'),
    SocialLinkInfo(platform: 'twitter', url: 'https://x.com/mjengohub'),
    SocialLinkInfo(platform: 'tiktok', url: 'https://tiktok.com/@mjengohub'),
    SocialLinkInfo(platform: 'facebook', url: 'https://facebook.com/mjengohub'),
    SocialLinkInfo(platform: 'instagram', url: 'https://instagram.com/mjengohub'),
    SocialLinkInfo(platform: 'whatsapp', url: 'https://whatsapp.com/channel/mjengohub'),
    SocialLinkInfo(platform: 'telegram', url: 'https://t.me/mjengohub'),
  ];

  final _service = SiteService();
  List<SocialLinkInfo> _links = _fallbackLinks;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final fetched = await _service.getSocialLinks();
    if (!mounted || fetched.isEmpty) return;
    setState(() => _links = fetched);
  }

  static const Map<String, IconData> _iconFor = {
    'youtube': Icons.smart_display_rounded,
    'twitter': Icons.close_rounded,
    'tiktok': Icons.music_note_rounded,
    'facebook': Icons.facebook_rounded,
    'instagram': Icons.camera_alt_rounded,
    'whatsapp': Icons.chat_rounded,
    'telegram': Icons.send_rounded,
    'linkedin': Icons.business_center_rounded,
    'other': Icons.link_rounded,
  };

  static const Map<String, Color> _colorFor = {
    'youtube': Color(0xFFFF0000),
    'twitter': Colors.black,
    'tiktok': Colors.black,
    'facebook': Color(0xFF1877F2),
    'instagram': Color(0xFFE1306C),
    'whatsapp': Color(0xFF25D366),
    'telegram': Color(0xFF229ED9),
    'linkedin': Color(0xFF0A66C2),
    'other': AppColors.textSubtle,
  };

  static const Map<String, String> _labelFor = {
    'youtube': 'YouTube',
    'twitter': 'X',
    'tiktok': 'TikTok',
    'facebook': 'Facebook',
    'instagram': 'Instagram',
    'whatsapp': 'WhatsApp',
    'telegram': 'Telegram',
    'linkedin': 'LinkedIn',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionHeader(title: 'Follow Mjengo Hub'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: GestureDetector(
            onTap: () => _launchExternal(_mjengoNetworksUrl),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: AppColors.verifiedPillGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(11)),
                    child: const Icon(Icons.hub_rounded, color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Mjengo Networks', style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w800, color: Colors.white)),
                        const SizedBox(height: 2),
                        Text('Our wider media & social network', style: GoogleFonts.montserrat(fontSize: 11, color: Colors.white.withValues(alpha: 0.9))),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 16),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _links
                .map((l) => _SocialIcon(
                      icon: _iconFor[l.platform] ?? Icons.link_rounded,
                      color: _colorFor[l.platform] ?? AppColors.textSubtle,
                      url: l.url,
                      label: l.label?.isNotEmpty == true ? l.label! : (_labelFor[l.platform] ?? l.platform),
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _SocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String url;
  final String label;
  const _SocialIcon({required this.icon, required this.color, required this.url, required this.label});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _launchExternal(url),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(height: 4),
          Text(label, style: GoogleFonts.montserrat(fontSize: 9.5, color: AppColors.textSubtle, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Featured Projects
//
//  Mirrors the website's "Latest/Featured Infrastructure Projects" and
//  "Latest/Featured Private Projects" sections (templates/homepage.html),
//  collapsed into one horizontally-scrolling row since a phone screen can't
//  afford four separate full-width sections. Each card carries the same
//  fields as the website's `ph-card`: image, status pill, title, location,
//  and a completion progress bar.
// ─────────────────────────────────────────────────────────────────────────────

class FeaturedProjectsSection extends StatefulWidget {
  const FeaturedProjectsSection({super.key});

  @override
  State<FeaturedProjectsSection> createState() => _FeaturedProjectsSectionState();
}

class _FeaturedProjectsSectionState extends State<FeaturedProjectsSection> {
  final _service = ProjectsService();
  List<Project> _projects = [];
  bool _loading = true;
  bool _isDemo = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _service.getPublicProjects(featured: true, perPage: 4),
      _service.getPrivateProjects(featured: true, perPage: 4),
    ]);
    if (!mounted) return;
    final merged = [...results[0], ...results[1]];
    if (merged.isEmpty) {
      setState(() {
        _projects = demoProjects();
        _isDemo = true;
        _loading = false;
      });
      return;
    }
    setState(() {
      _projects = merged;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _projects.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(
          title: 'Featured Projects',
          onSeeAll: () => Get.toNamed(AppRoutes.projects),
          isDemo: _isDemo,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Infrastructure and private developments tracked across Kenya',
            style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 232,
          child: _loading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => Container(
                    width: 220,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _projects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _FeaturedProjectCard(project: _projects[i]),
                ),
        ),
      ],
    );
  }
}

class _FeaturedProjectCard extends StatelessWidget {
  final Project project;
  const _FeaturedProjectCard({required this.project});

  static const _statusColors = {
    'ongoing': AppColors.warning,
    'completed': AppColors.success,
    'suspended': AppColors.danger,
    'planned': AppColors.accentBlue,
  };

  @override
  Widget build(BuildContext context) {
    final isPrivate = project.isPrivateProject;
    final statusColor = _statusColors[project.status] ?? AppColors.textSubtle;

    return GestureDetector(
      onTap: () => Get.to(() => ProjectDetailScreen(slug: project.slug), transition: Transition.cupertino),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.divider),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 110,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                    url: project.imageUrl,
                    fit: BoxFit.cover,
                    placeholderColor: isPrivate
                        ? AppColors.primeBadge.withValues(alpha: 0.85)
                        : const Color(0xFF1E3A5F),
                  ),
                  Positioned(
                    top: 8,
                    left: 8,
                    child: _pill(
                      isPrivate ? 'PRIVATE' : 'PUBLIC',
                      isPrivate ? AppColors.primeBadge : AppColors.accentBlue,
                    ),
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: _pill(project.statusLabel.toUpperCase(), statusColor),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textDark),
                  ),
                  if ((project.county ?? project.location) != null) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 11, color: AppColors.textSubtle),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            project.county ?? project.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(fontSize: 10.5, color: AppColors.textSubtle),
                          ),
                        ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: (project.progressPercent.clamp(0, 100)) / 100,
                      minHeight: 5,
                      backgroundColor: AppColors.divider,
                      color: isPrivate ? AppColors.primeBadge : AppColors.accentBlue,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${project.progressPercent}% complete',
                    style: GoogleFonts.montserrat(fontSize: 10, color: AppColors.textSubtle),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
        child: Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 7.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Safety Incidents
//
//  Mirrors the website's "Road Safety: Share Barabara" and "Site Safety
//  Database" preview strips (templates/homepage.html), but shows real recent
//  incidents instead of a static CTA banner — the app already has both
//  datasets wired (`IncidentsService`), so a content preview is more useful
//  here than a link-out card.
// ─────────────────────────────────────────────────────────────────────────────

class SafetyIncidentsSection extends StatefulWidget {
  const SafetyIncidentsSection({super.key});

  @override
  State<SafetyIncidentsSection> createState() => _SafetyIncidentsSectionState();
}

class _SafetyIncidentsSectionState extends State<SafetyIncidentsSection> {
  final _service = IncidentsService();
  List<Incident> _incidents = [];
  bool _loading = true;
  bool _isDemo = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      _service.getIncidents(type: 'road_safety', perPage: 4),
      _service.getIncidents(type: 'site_safety', perPage: 4),
    ]);
    if (!mounted) return;
    final merged = [...results[0], ...results[1]];
    if (merged.isEmpty) {
      setState(() {
        _incidents = demoIncidents();
        _isDemo = true;
        _loading = false;
      });
      return;
    }
    setState(() {
      _incidents = merged;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _incidents.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              const Text(
                'Safety Incidents',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark),
              ),
              if (_isDemo) const Padding(padding: EdgeInsets.only(left: 8), child: PreviewDataBadge()),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Road hazards and construction site incidents from across Kenya',
            style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 172,
          child: _loading
              ? ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: 3,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, __) => Container(
                    width: 200,
                    decoration: BoxDecoration(
                      color: AppColors.divider,
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                )
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _incidents.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _SafetyIncidentCard(incident: _incidents[i]),
                ),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              Expanded(
                child: _ctaChip(
                  label: 'Road Safety',
                  color: const Color(0xFFDC2626),
                  onTap: () => Get.toNamed(AppRoutes.shareBarabara),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ctaChip(
                  label: 'Site Safety',
                  color: AppColors.warning,
                  onTap: () => Get.toNamed(AppRoutes.siteSafety),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ctaChip({required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w700, color: color),
        ),
      ),
    );
  }
}

class _SafetyIncidentCard extends StatelessWidget {
  final Incident incident;
  const _SafetyIncidentCard({required this.incident});

  /// Matches the palette used in `incidents_list_screen.dart` — incidents use
  /// their own severity scale (minor/moderate/serious/fatal), distinct from
  /// the low/medium/high/critical scale used by infrastructure reports.
  static const _severityColors = {
    'fatal': Color(0xFF7F1D1D),
    'serious': Color(0xFFDC2626),
    'moderate': Color(0xFFF97316),
    'minor': Color(0xFF22C55E),
  };

  @override
  Widget build(BuildContext context) {
    final isRoad = incident.isRoadSafety;
    final severityColor = _severityColors[incident.severity] ?? AppColors.textSubtle;

    return GestureDetector(
      onTap: () => Get.toNamed(AppRoutes.incidentDetail, arguments: incident.slug),
      child: Container(
        width: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 88,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                    url: incident.imageUrl,
                    fit: BoxFit.cover,
                    placeholderColor: isRoad ? const Color(0xFF7F1D1D) : const Color(0xFF78350F),
                    placeholderIcon: Icons.report_problem_rounded,
                  ),
                  Positioned(
                    top: 7,
                    left: 7,
                    child: _pill(isRoad ? 'ROAD' : 'SITE', isRoad ? const Color(0xFFDC2626) : AppColors.warning),
                  ),
                  Positioned(
                    top: 7,
                    right: 7,
                    child: _pill(incident.severity.toUpperCase(), severityColor),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    incident.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.textDark, height: 1.3),
                  ),
                  if ((incident.county ?? incident.location) != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.place_outlined, size: 11, color: AppColors.textSubtle),
                        const SizedBox(width: 2),
                        Expanded(
                          child: Text(
                            incident.county ?? incident.location!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(fontSize: 10.5, color: AppColors.textSubtle),
                          ),
                        ),
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

  Widget _pill(String label, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
        child: Text(
          label,
          style: GoogleFonts.montserrat(fontSize: 7.5, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: 0.3),
        ),
      );
}
