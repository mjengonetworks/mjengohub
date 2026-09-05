// lib/profile/screens/followed_projects_screen.dart
//
// Full list of the signed-in user's followed projects — "View All" target
// from the Profile screen's My Followed Projects preview. Backed by
// `GET /auth/me/followed-projects`.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../projects/models/project_model.dart';
import '../../projects/screens/project_detail_screen.dart';
import '../../projects/services/projects_service.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/coming_soon.dart';
import '../../shared/widgets/responsive.dart';

class FollowedProjectsScreen extends StatefulWidget {
  const FollowedProjectsScreen({super.key});

  @override
  State<FollowedProjectsScreen> createState() => _FollowedProjectsScreenState();
}

class _FollowedProjectsScreenState extends State<FollowedProjectsScreen> {
  final _service = ProjectsService();
  late Future<List<Project>> _future = _service.getFollowedProjects(perPage: 50);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColors.textDark,
        title: Text('Followed Projects',
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w500, fontSize: 16, color: AppColors.textDark)),
      ),
      body: ContentWidth(
        maxWidth: 700,
        child: RefreshIndicator(
          onRefresh: () async {
            setState(() => _future = _service.getFollowedProjects(perPage: 50));
            await _future;
          },
          child: FutureBuilder<List<Project>>(
            future: _future,
            builder: (context, snap) {
              if (!snap.hasData) return const Center(child: CircularProgressIndicator());
              final items = snap.data!;
              if (items.isEmpty) {
                return const ComingSoonPlaceholder(
                  icon: Icons.notifications_none_rounded,
                  title: 'No followed projects yet',
                  message: 'Tap the bell icon on any project to follow its updates.',
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: items.length,
                separatorBuilder: (_, __) => const Divider(height: 1, color: AppColors.divider),
                itemBuilder: (_, i) {
                  final p = items[i];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: SizedBox(
                        width: 52,
                        height: 52,
                        child: NetImage(url: p.imageUrl, fit: BoxFit.cover, placeholderColor: const Color(0xFF1E3A5F)),
                      ),
                    ),
                    title: Text(p.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.montserrat(fontSize: 13.5, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                    subtitle: Text(p.county ?? p.location ?? p.statusLabel,
                        style: GoogleFonts.montserrat(fontSize: 11.5, color: AppColors.textSubtle)),
                    onTap: () => Get.to(() => ProjectDetailScreen(slug: p.slug), transition: Transition.cupertino),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}
