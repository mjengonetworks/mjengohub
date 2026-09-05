// lib/home/widgets/home_extra_sections.dart
//
// New homepage sections for web/app parity: "Featured Articles & Analysis"
// (title-only), "Browse Projects by Category" (mixed public/private grid),
// and "Follow Mjengo Hub" (Mjengo Networks preview + social cluster).
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../incidents/models/incident_model.dart';
import '../../incidents/services/incidents_service.dart';
import '../../merch/models/merch_model.dart';
import '../../merch/screens/merch_screen.dart';
import '../../merch/services/merch_service.dart';
import '../../navigation/main_navigation.dart';
import '../../news/controllers/discover_controller.dart';
import '../../news/models/article_model.dart';
import '../../news/models/category_model.dart';
import '../../news/screens/article_detail_screen.dart';
import '../../news/services/news_api_service.dart';
import '../../news/widgets/net_image.dart';
import '../../point/models/contributors_model.dart';
import '../../point/routes/app_routes.dart';
import '../../point/services/contributors_service.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/africa_world_screen.dart';
import '../../projects/screens/built_history_screen.dart';
import '../../projects/screens/private_projects_screen.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/projects_service.dart';
import '../../projects/widgets/tracker_project_card.dart';
import '../../shared/services/demo_seed_data.dart';
import '../../shared/services/site_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/preview_data_badge.dart';
import '../../shared/widgets/section_header.dart' as shared;
import '../../videos/models/video_model.dart';
import '../../videos/screens/video_player_screen.dart';
import '../../videos/services/video_api_service.dart';

/// Opens in an in-app browser (Custom Tabs / SFSafariViewController) rather
/// than handing off to the system browser — matches X/Twitter's in-app link
/// behavior, so the user never perceives leaving the app.
Future<void> _launchExternal(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
}

// ── Section header (shared look across the three sections) ──────────────────

/// Thin wrapper kept so the ~10 call sites in this file don't need touching —
/// delegates to the shared, sharp-styled `SectionHeader` (Spec 1/10).
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  final bool isDemo;
  final String seeAllLabel;

  const _SectionHeader({required this.title, this.onSeeAll, this.isDemo = false, this.seeAllLabel = 'See All'});

  @override
  Widget build(BuildContext context) {
    return shared.SectionHeader(title: title, onSeeAll: onSeeAll, isDemo: isDemo, seeAllLabel: seeAllLabel);
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
                        style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.accentBlue)),
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
    final projects = await _service.getProjects(featured: true, perPage: 8);
    if (!mounted) return;
    if (projects.isEmpty) {
      setState(() {
        _projects = demoProjects();
        _isDemo = true;
        _loading = false;
      });
      return;
    }
    setState(() {
      _projects = projects.take(4).toList();
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
                        color: AppColors.accentBlue,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        project.statusLabel.toUpperCase(),
                        style: GoogleFonts.montserrat(fontSize: 8, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.4),
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
                style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textDark, height: 1.25),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

// ── Ecosystem cross-promotion: two standalone banners (Mjengo Networks,
// Share Barabara) placed at separate points in the homepage's interleaved
// flow (see home_screen.dart), plus a separate social-links grid — split
// out of the old combined "Follow Mjengo Hub" section, which bundled all
// three into one block. ───────────────────────────────────────────────────

class _EcosystemBanner extends StatefulWidget {
  final String heroImagePageKey;
  final String url;
  final IconData fallbackIcon;
  final String title;
  final String subtitle;
  final String ctaLabel;
  final Decoration Function() background;

  const _EcosystemBanner({
    required this.heroImagePageKey,
    required this.url,
    required this.fallbackIcon,
    required this.title,
    required this.subtitle,
    required this.ctaLabel,
    required this.background,
  });

  @override
  State<_EcosystemBanner> createState() => _EcosystemBannerState();
}

class _EcosystemBannerState extends State<_EcosystemBanner> {
  final _service = SiteService();
  String? _icon;

  @override
  void initState() {
    super.initState();
    _service.getHeroImages(pageKey: widget.heroImagePageKey).then((icons) {
      if (mounted && icons.isNotEmpty) setState(() => _icon = icons.first.image);
    });
  }

  @override
  Widget build(BuildContext context) {
    // Standalone card, not a tappable strip: icon + heading + copy stacked
    // above an explicit CTA button — mirrors the website's .ph-preview-card
    // (an icon/heading/paragraph row followed by its own <a class="btn">),
    // rather than the whole card doubling as one big tap target.
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: widget.background(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _EcosystemIcon(imageUrl: _icon, fallbackIcon: widget.fallbackIcon),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.title, style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(widget.subtitle,
                          style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white.withValues(alpha: 0.92), height: 1.4)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _launchExternal(widget.url),
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(widget.ctaLabel,
                    style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textDark)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MjengoNetworksBanner extends StatelessWidget {
  const MjengoNetworksBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return _EcosystemBanner(
      heroImagePageKey: 'hero_cta_mjengo_networks',
      url: 'https://mjengonetworks.co.ke/',
      fallbackIcon: Icons.hub_rounded,
      title: 'Mjengo Networks',
      subtitle: 'Mjengo Networks — redefining construction networking in Kenya '
          'and beyond. Mjengo Hub is proudly built and run by Mjengo Networks.',
      ctaLabel: 'Visit Mjengo Networks →',
      background: () => BoxDecoration(gradient: AppColors.verifiedPillGradient, borderRadius: BorderRadius.circular(14)),
    );
  }
}

class ShareBarabaraBanner extends StatelessWidget {
  const ShareBarabaraBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return _EcosystemBanner(
      heroImagePageKey: 'hero_cta_share_barabara',
      url: 'https://sharebarabara.co.ke',
      fallbackIcon: Icons.directions_car_filled_rounded,
      title: 'Share Barabara',
      subtitle: 'Report and track road conditions across Kenya, together with fellow road users.',
      ctaLabel: 'Visit Share Barabara →',
      background: () => BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(14)),
    );
  }
}

class SocialLinksGrid extends StatefulWidget {
  const SocialLinksGrid({super.key});

  @override
  State<SocialLinksGrid> createState() => _SocialLinksGridState();
}

class _SocialLinksGridState extends State<SocialLinksGrid> {
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
    _service.getSocialLinks().then((links) {
      if (mounted && links.isNotEmpty) setState(() => _links = links);
    });
  }

  // Authentic brand silhouettes (FontAwesome Free) rather than generic
  // Material shapes -- tiktok/telegram/other have no brand icon required by
  // the spec, so those keep a plain Material glyph.
  static const Map<String, IconData> _iconFor = {
    'youtube': FontAwesomeIcons.youtube,
    'twitter': FontAwesomeIcons.xTwitter,
    'tiktok': Icons.music_note_rounded,
    'facebook': FontAwesomeIcons.facebookF,
    'instagram': FontAwesomeIcons.instagram,
    'whatsapp': FontAwesomeIcons.whatsapp,
    'telegram': Icons.send_rounded,
    'linkedin': FontAwesomeIcons.linkedinIn,
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
        const SizedBox(height: 20),
        const _NetworkSitesDirectory(),
      ],
    );
  }
}

/// The Mjengo Networks ecosystem's registered properties. Only these three
/// are confirmed (the same URLs already used elsewhere in this app, e.g.
/// HubScreen's ecosystem links) -- not fabricating additional sub-sites
/// beyond what's actually established.
class _NetworkSitesDirectory extends StatelessWidget {
  const _NetworkSitesDirectory();

  static const _sites = [
    (label: 'Mjengo Hub', domain: 'mjengohub.co.ke', url: 'https://mjengohub.co.ke'),
    (label: 'Share Barabara', domain: 'sharebarabara.co.ke', url: 'https://sharebarabara.co.ke'),
    (label: 'Mjengo Networks', domain: 'mjengonetworks.co.ke', url: 'https://mjengonetworks.co.ke/'),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Our Network', style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textSubtle, letterSpacing: 0.4)),
          const SizedBox(height: 8),
          for (final site in _sites)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => _launchExternal(site.url),
                child: Row(
                  children: [
                    const Icon(Icons.public, size: 14, color: AppColors.accentBlue),
                    const SizedBox(width: 8),
                    Text(site.label, style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                    const SizedBox(width: 6),
                    Text(site.domain, style: GoogleFonts.montserrat(fontSize: 11.5, color: AppColors.textSubtle)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Circular brand icon for the Mjengo Networks / Share Barabara banners.
/// The logo is scaled to ~76% of the circle's diameter with inner padding
/// so it sits comfortably centered without grazing the circle's edge.
/// Falls back to a plain Material icon if no admin-managed brand icon
/// (`GET site/hero-images?page_key=hero_cta_*`) is configured yet.
class _EcosystemIcon extends StatelessWidget {
  final String? imageUrl;
  final IconData fallbackIcon;
  static const double _diameter = 46;

  const _EcosystemIcon({required this.imageUrl, required this.fallbackIcon});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: _diameter,
      height: _diameter,
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), shape: BoxShape.circle),
      child: (imageUrl != null && imageUrl!.isNotEmpty)
          ? Padding(
              padding: const EdgeInsets.all(_diameter * 0.12),
              child: ClipOval(
                child: NetImage(url: imageUrl, fit: BoxFit.contain, placeholderColor: Colors.transparent),
              ),
            )
          : Icon(fallbackIcon, color: Colors.white, size: 22),
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
  /// false = "Latest Infrastructure Projects" (unfiltered, newest first);
  /// true = "Featured Public Projects" (featured=true cut). Both are the
  /// same infrastructure tracker data, just a different slice — Spec 10
  /// sections 5 and 17.
  final bool featured;
  final String title;
  final String subtitle;

  const FeaturedProjectsSection({
    super.key,
    this.featured = true,
    this.title = 'Featured Infrastructure Projects',
    this.subtitle = 'Roads, bridges and major public infrastructure tracked across Kenya',
  });

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
    // Infrastructure only — Private Developments gets its own dedicated
    // showcase section (PrivateDevelopmentsShowcaseSection) further down the
    // homepage, so the two don't show overlapping cards.
    var projects = await _service.getProjects(featured: widget.featured, projectType: 'infrastructure', perPage: 8);
    // Spec 8: guaranteed fallback — an empty featured cut falls back to the
    // general unfiltered list before resorting to demo data.
    if (projects.isEmpty && widget.featured) {
      projects = await _service.getProjects(projectType: 'infrastructure', perPage: 8);
    }
    if (!mounted) return;
    if (projects.isEmpty) {
      setState(() {
        _projects = demoProjects();
        _isDemo = true;
        _loading = false;
      });
      return;
    }
    setState(() {
      _projects = projects;
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
          title: widget.title,
          onSeeAll: () => Get.toNamed(AppRoutes.projects),
          isDemo: _isDemo,
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            widget.subtitle,
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
                  itemCount: _projects.take(4).length,
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
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                    url: project.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholderColor: const Color(0xFF1E3A5F),
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
                    style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textDark),
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
                      color: AppColors.accentBlue,
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
          style: GoogleFonts.montserrat(fontSize: 7.5, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.3),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Built History preview — homepage carousel for the archive tracker
//  (Project.is_built_history=True, same Project rows as every other
//  tracker, just filtered/labeled differently). Links out to
//  BuiltHistoryScreen.
// ─────────────────────────────────────────────────────────────────────────────

class BuiltHistoryPreviewSection extends StatefulWidget {
  const BuiltHistoryPreviewSection({super.key});

  @override
  State<BuiltHistoryPreviewSection> createState() => _BuiltHistoryPreviewSectionState();
}

class _BuiltHistoryPreviewSectionState extends State<BuiltHistoryPreviewSection> {
  final _service = ProjectsService();
  List<Project> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var p = await _service.getProjects(isBuiltHistory: true, perPage: 8);
    // Spec 8: guaranteed fallback — never leave this module blank.
    if (p.isEmpty) p = await _service.getProjects(perPage: 8);
    if (!mounted) return;
    setState(() {
      _projects = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _projects.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Built History', onSeeAll: () => Get.to(() => const BuiltHistoryScreen())),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Kenya\'s architectural and infrastructure heritage',
            style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _projects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => TrackerProjectCard(
                    project: _projects[i],
                    captionOverride: _projects[i].completionDecade,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Africa & World spotlight preview — homepage carousel for curated
//  international entries (Project.geo_scope='global'). Links out to
//  AfricaWorldScreen.
// ─────────────────────────────────────────────────────────────────────────────

class AfricaWorldPreviewSection extends StatefulWidget {
  const AfricaWorldPreviewSection({super.key});

  @override
  State<AfricaWorldPreviewSection> createState() => _AfricaWorldPreviewSectionState();
}

class _AfricaWorldPreviewSectionState extends State<AfricaWorldPreviewSection> {
  final _service = ProjectsService();
  List<Project> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var p = await _service.getProjects(geoScope: 'global', perPage: 8);
    // Spec 8: guaranteed fallback — never leave this module blank.
    if (p.isEmpty) p = await _service.getProjects(perPage: 8);
    if (!mounted) return;
    setState(() {
      _projects = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _projects.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionHeader(title: 'Africa & World', onSeeAll: () => Get.to(() => const AfricaWorldScreen())),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Landmark projects from across the continent and beyond',
            style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _projects.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => TrackerProjectCard(
                    project: _projects[i],
                    captionOverride: _projects[i].country,
                  ),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Private Developments showcase — homepage carousel for
//  project_type='private_development' (Housing, Commercial, ...). Links out
//  to PrivateProjectsScreen (already the dedicated screen for this tracker).
// ─────────────────────────────────────────────────────────────────────────────

class PrivateDevelopmentsShowcaseSection extends StatefulWidget {
  /// Spec 10 sections 7 ("Latest Private Projects", unfiltered) and 19
  /// ("Featured Private Projects", featured=true) — same tracker data,
  /// different slice.
  final bool featured;
  final String title;

  const PrivateDevelopmentsShowcaseSection({super.key, this.featured = false, this.title = 'Private Developments'});

  @override
  State<PrivateDevelopmentsShowcaseSection> createState() => _PrivateDevelopmentsShowcaseSectionState();
}

class _PrivateDevelopmentsShowcaseSectionState extends State<PrivateDevelopmentsShowcaseSection> {
  final _service = ProjectsService();
  List<Project> _projects = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    var projects = await _service.getProjects(projectType: 'private_development', featured: widget.featured, perPage: 8);
    // Spec 8: guaranteed fallback — an empty featured cut falls back to the
    // general unfiltered list.
    if (projects.isEmpty && widget.featured) {
      projects = await _service.getProjects(projectType: 'private_development', perPage: 8);
    }
    if (!mounted) return;
    setState(() {
      _projects = projects;
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
          title: widget.title,
          onSeeAll: () => Get.to(() => const PrivateProjectsScreen()),
          seeAllLabel: 'View All Private Projects',
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Buildings — residential, commercial and mixed-use developments',
            style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 190,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _projects.take(4).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => TrackerProjectCard(project: _projects[i]),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Safety Incidents
//
//  Mirrors the website's "Site Safety Database" preview strip
//  (templates/homepage.html), but shows real recent incidents instead of a
//  static CTA banner. Site-safety only — road-safety ("Share Barabara") was
//  removed entirely, in-app list screen and preview cards both, since it
//  never actually opened the external sharebarabara.co.ke site it was named
//  after.
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
    final results = await _service.getIncidents(type: 'site_safety', perPage: 8);
    if (!mounted) return;
    if (results.isEmpty) {
      setState(() {
        _incidents = demoIncidents().where((i) => i.incidentType == 'site_safety').toList();
        _isDemo = true;
        _loading = false;
      });
      return;
    }
    setState(() {
      _incidents = results;
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
                'Site Safety',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AppColors.textDark),
              ),
              if (_isDemo) const Padding(padding: EdgeInsets.only(left: 8), child: PreviewDataBadge()),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Construction site incidents from across Kenya',
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
          child: _ctaChip(
            label: 'View All Incidents',
            color: AppColors.warning,
            onTap: () => Get.toNamed(AppRoutes.siteSafety),
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
          style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500, color: color),
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
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(
                    url: incident.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
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
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.textDark, height: 1.3),
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
          style: GoogleFonts.montserrat(fontSize: 7.5, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.3),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  Browse Articles by Category — homepage pill bar (Spec 10 section 3).
//  Tapping a pill switches to the Discover tab pre-filtered to that
//  category, reusing DiscoverController.selectCategory exactly like the
//  Discover screen's own _CategoryTabs.
// ─────────────────────────────────────────────────────────────────────────────

class CategoryPillsBar extends StatefulWidget {
  const CategoryPillsBar({super.key});

  @override
  State<CategoryPillsBar> createState() => _CategoryPillsBarState();
}

class _CategoryPillsBarState extends State<CategoryPillsBar> {
  final _service = NewsApiService();
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _service.getCategories().then((cats) {
      if (mounted) setState(() => _categories = cats);
    });
  }

  void _openCategory(String slug) {
    if (Get.isRegistered<DiscoverController>()) {
      Get.find<DiscoverController>().selectCategory(slug);
    }
    Get.find<MainNavController>().currentIndex.value = MainNavController.tabNews;
  }

  @override
  Widget build(BuildContext context) {
    if (_categories.isEmpty) return const SizedBox.shrink();
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = _categories[i];
          return GestureDetector(
            onTap: () => _openCategory(cat.slug),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppRadius.sharpLg),
                border: Border.all(color: AppColors.borderSlate),
              ),
              child: Text(
                cat.name,
                style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.bodyCharcoal),
              ),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Media / YouTube — Spec 10 sections 11-12. There is no separate MediaScreen
//  in this app; both slots point at the Videos tab, the closest existing
//  equivalent (VideosService/VideosScreen).
// ─────────────────────────────────────────────────────────────────────────────

class MediaPreviewBanner extends StatelessWidget {
  const MediaPreviewBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GestureDetector(
        onTap: () => Get.find<MainNavController>().currentIndex.value = MainNavController.tabMedia,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppRadius.sharp),
            border: Border.all(color: AppColors.borderSlate),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                alignment: Alignment.center,
                decoration: BoxDecoration(color: AppColors.accentBlue.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(AppRadius.sharp)),
                child: const Icon(Icons.perm_media_outlined, color: AppColors.accentBlue, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Media Hub', style: GoogleFonts.montserrat(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.headingSlate)),
                    const SizedBox(height: 2),
                    Text('Photos, videos and site coverage in one place',
                        style: GoogleFonts.montserrat(fontSize: 11.5, color: AppColors.captionSlate)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward, size: 16, color: AppColors.captionSlate),
            ],
          ),
        ),
      ),
    );
  }
}

class YoutubeCarouselSection extends StatefulWidget {
  const YoutubeCarouselSection({super.key});

  @override
  State<YoutubeCarouselSection> createState() => _YoutubeCarouselSectionState();
}

class _YoutubeCarouselSectionState extends State<YoutubeCarouselSection> {
  final _service = VideoApiService();
  List<Video> _videos = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.getVideos(perPage: 8).then((v) {
      if (!mounted) return;
      setState(() {
        _videos = v;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _videos.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shared.SectionHeader(
          title: 'Mjengo Hub on YouTube',
          onSeeAll: () => Get.find<MainNavController>().currentIndex.value = MainNavController.tabMedia,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 168,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _videos.take(4).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _VideoCard(video: _videos[i]),
                ),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final Video video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => VideoPlayerScreen(video: video)),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          border: Border.all(color: AppColors.borderSlate),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  NetImage(url: video.thumbnailUrl, fit: BoxFit.cover, placeholderColor: const Color(0xFF0F172A)),
                  const Center(child: Icon(Icons.play_circle_fill_rounded, color: Colors.white, size: 36)),
                  if (video.duration != null && video.duration!.isNotEmpty)
                    Positioned(
                      right: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.75), borderRadius: BorderRadius.circular(4)),
                        child: Text(video.duration!,
                            style: GoogleFonts.montserrat(fontSize: 10, fontWeight: FontWeight.w500, color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                video.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.headingSlate, height: 1.3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Merch preview — Spec 10 sections 15/20. Reuses MerchService, routes to
//  the standalone MerchScreen ("Buy" happens there, not from the homepage).
// ─────────────────────────────────────────────────────────────────────────────

class MerchPreviewSection extends StatefulWidget {
  final String title;
  const MerchPreviewSection({super.key, this.title = 'Mjengo Hub Merch'});

  @override
  State<MerchPreviewSection> createState() => _MerchPreviewSectionState();
}

class _MerchPreviewSectionState extends State<MerchPreviewSection> {
  final _service = MerchService();
  List<MerchProduct> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.getProducts().then((p) {
      if (!mounted) return;
      setState(() {
        _products = p;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _products.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shared.SectionHeader(title: widget.title, onSeeAll: () => Get.to(() => const MerchScreen())),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: _loading
              ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
              : ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: _products.take(4).length,
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (_, i) => _MerchCard(product: _products[i]),
                ),
        ),
      ],
    );
  }
}

class _MerchCard extends StatelessWidget {
  final MerchProduct product;
  const _MerchCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const MerchScreen()),
      child: Container(
        width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.sharp),
          border: Border.all(color: AppColors.borderSlate),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: NetImage(url: product.image, fit: BoxFit.cover, placeholderColor: const Color(0xFFF1F5F9)),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.headingSlate)),
                  const SizedBox(height: 2),
                  Text('KES ${product.price.toStringAsFixed(0)}',
                      style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.accentBlue)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  More News & Articles — Spec 10 sections 23/25 (Part 1/2), further
//  pagination pages beyond what Breaking News + Featured Analysis already
//  show, so the two parts don't repeat the same headlines.
// ─────────────────────────────────────────────────────────────────────────────

class MoreNewsSection extends StatefulWidget {
  final String title;
  final int page;
  const MoreNewsSection({super.key, required this.title, required this.page});

  @override
  State<MoreNewsSection> createState() => _MoreNewsSectionState();
}

class _MoreNewsSectionState extends State<MoreNewsSection> {
  final _service = NewsApiService();
  List<Article> _articles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _service.getArticles(page: widget.page, perPage: 4).then((a) {
      if (!mounted) return;
      setState(() {
        _articles = a;
        _loading = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _articles.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        shared.SectionHeader(
          title: widget.title,
          onSeeAll: () => Get.find<MainNavController>().currentIndex.value = MainNavController.tabNews,
        ),
        const SizedBox(height: 12),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
          )
        else
          for (int i = 0; i < _articles.length; i++) ...[
            GestureDetector(
              onTap: () => Get.toNamed(AppRoutes.articleDetail, arguments: _articles[i].slug),
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sharp),
                      child: SizedBox(
                        width: 68,
                        height: 52,
                        child: NetImage(url: _articles[i].imageUrl, fit: BoxFit.cover, placeholderColor: const Color(0xFF0F172A)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _articles[i].title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.headingSlate, height: 1.3),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (i != _articles.length - 1)
              const Padding(padding: EdgeInsets.symmetric(horizontal: 20), child: Divider(height: 1, color: AppColors.borderSlate)),
          ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Join Our Community — Spec 10 section 26: top-3 weekly contributors +
//  CTA to ContributorsScreen. Falls back to the all-time projects metric if
//  the points metric has no rows this week, so the section is never blank
//  whenever there's any contributor activity at all.
// ─────────────────────────────────────────────────────────────────────────────

class CommunitySection extends StatefulWidget {
  const CommunitySection({super.key});

  @override
  State<CommunitySection> createState() => _CommunitySectionState();
}

class _CommunitySectionState extends State<CommunitySection> {
  final _service = ContributorsService();
  List<LeaderboardRow> _top = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final boards = await _service.getContributors(limit: 3);
    var top = boards.points.profiles;
    if (top.isEmpty) top = boards.projects.profiles;
    if (!mounted) return;
    setState(() {
      _top = top.take(3).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_loading && _top.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.headingSlate,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Join Our Community', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: Colors.white)),
          const SizedBox(height: 2),
          Text('This week\'s top contributors',
              style: GoogleFonts.montserrat(fontSize: 12, color: Colors.white.withValues(alpha: 0.75))),
          const SizedBox(height: 14),
          if (_loading)
            const Center(child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
          else
            Row(
              children: [
                for (final row in _top) ...[
                  Expanded(child: _ContributorAvatar(row: row)),
                  if (row != _top.last) const SizedBox(width: 8),
                ],
              ],
            ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Get.toNamed(AppRoutes.contributors),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 11),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sharp)),
              ),
              child: Text('Join Community →',
                  style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.headingSlate)),
            ),
          ),
        ],
      ),
    );
  }
}

class _ContributorAvatar extends StatelessWidget {
  final LeaderboardRow row;
  const _ContributorAvatar({required this.row});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipOval(
          child: SizedBox(
            width: 44,
            height: 44,
            child: NetImage(url: row.avatar, fit: BoxFit.cover, placeholderColor: Colors.white.withValues(alpha: 0.15)),
          ),
        ),
        const SizedBox(height: 6),
        Text(row.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 11, fontWeight: FontWeight.w500, color: Colors.white)),
        Text('${row.value} pts',
            style: GoogleFonts.montserrat(fontSize: 9.5, color: Colors.white.withValues(alpha: 0.7))),
      ],
    );
  }
}
