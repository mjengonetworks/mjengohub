// lib/home/widgets/home_extra_sections.dart
//
// New homepage sections for web/app parity: "Featured Articles & Analysis"
// (title-only), "Browse Projects by Category" (mixed public/private grid),
// and "Follow Mjengo Hub" (Mjengo Networks preview + social cluster).
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../news/models/article_model.dart';
import '../../point/routes/app_routes.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/projects_service.dart';
import '../../shared/services/site_service.dart';
import '../../shared/theme/app_theme.dart';

Future<void> _launchExternal(String url) async {
  final uri = Uri.parse(url);
  if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
}

// ── Section header (shared look across the three sections) ──────────────────

class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onSeeAll;
  const _SectionHeader({required this.title, this.onSeeAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: GoogleFonts.montserrat(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textDark)),
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
        _SectionHeader(title: 'Browse Projects by Category', onSeeAll: () => Get.toNamed(AppRoutes.projects)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: _loading
              ? SizedBox(
                  height: 160,
                  child: GridView.builder(
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
          border: Border.all(color: AppColors.divider),
          boxShadow: const [BoxShadow(color: Color(0x06000000), blurRadius: 8, offset: Offset(0, 3))],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  project.imageUrl != null
                      ? Image.network(project.imageUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                      : _placeholder(),
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

  Widget _placeholder() => Container(
        color: const Color(0xFF1E3A5F),
        child: const Center(child: Icon(Icons.business_rounded, color: Colors.white38, size: 28)),
      );
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
