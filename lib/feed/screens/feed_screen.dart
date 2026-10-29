// lib/feed/screens/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../point/routes/app_routes.dart';
import '../../news/widgets/net_image.dart';
import '../../shared/services/link_launcher.dart';
import '../../shared/theme/app_theme.dart';
import '../controllers/feed_controller.dart';
import '../models/feed_contract.dart';
import '../models/feed_model.dart';
import '../widgets/feed_vote_bar.dart';
import '../widgets/feed_report_button.dart';
import 'feed_composer_screen.dart';

/// Native Media & Feed timeline and authenticated text composer.
class FeedScreen extends StatefulWidget {
  final FeedController? controller;

  const FeedScreen({super.key, this.controller});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  FeedTab _selectedTab = FeedTab.forYou;
  late final FeedController _controller;
  late final ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ??
        (Get.isRegistered<FeedController>()
            ? Get.find<FeedController>()
            : Get.put(FeedController(), permanent: true));
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.extentAfter < 280) {
      _controller.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _selectTab(FeedTab tab) {
    setState(() => _selectedTab = tab);
  }

  Future<void> _openWebsiteFeed() =>
      LinkLauncher.openLink(context, FeedContract.websiteUrl);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.scaffoldBackgroundColor,
      child: RefreshIndicator(
        color: AppColors.accentBlue,
        onRefresh: _controller.refreshFeed,
        child: ListView(
          controller: _scrollController,
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 28),
          children: [
            Text(
              'Media & Feed',
              style: GoogleFonts.montserrat(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Built-environment stories, updates and community discussion.',
              style: GoogleFonts.montserrat(
                fontSize: 12.5,
                height: 1.4,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
              ),
            ),
            const SizedBox(height: 14),
            const _FollowStrip(),
            const SizedBox(height: 12),
            _SecondaryNavigation(
              selected: _selectedTab,
              onSelected: _selectTab,
            ),
            const SizedBox(height: 12),
            _ComposerCard(onOpen: _openComposer),
            const SizedBox(height: 12),
            if (_selectedTab.hasNativeApi)
              _NativeTimeline(
                controller: _controller,
                onOpenWebsite: _openWebsiteFeed,
              )
            else
              _TimelineUnavailable(
                selectedTab: _selectedTab,
                onOpenWebsite: _openWebsiteFeed,
              ),
            const SizedBox(height: 12),
            _MediaDirectoryCard(
              onOpen: () => Get.toNamed(AppRoutes.mediaDirectory),
            ),
          ],
        ),
      ),
    );
  }

  void _openComposer() {
    MjengoAuthController? auth;
    try {
      auth = Get.find<MjengoAuthController>();
    } catch (_) {}
    if (!(auth?.isAuthenticated ?? false)) {
      Get.toNamed(AppRoutes.login, arguments: {'returnTo': AppRoutes.feed});
      return;
    }
    Get.to(
      () => FeedComposerScreen(controller: _controller),
      transition: Transition.cupertino,
    );
  }
}

class _FollowStrip extends StatelessWidget {
  const _FollowStrip();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: Row(
        children: [
          const Icon(Icons.hub_rounded, color: Colors.white, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Follow Mjengo Hub',
              style: GoogleFonts.montserrat(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Text(
            'Coming soon',
            style: GoogleFonts.montserrat(
              color: Colors.white.withValues(alpha: 0.78),
              fontSize: 10.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryNavigation extends StatelessWidget {
  final FeedTab selected;
  final ValueChanged<FeedTab> onSelected;

  const _SecondaryNavigation({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: FeedTab.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 6),
        itemBuilder: (_, index) {
          final tab = FeedTab.values[index];
          final active = selected == tab;
          return ChoiceChip(
            label: Text(tab.label),
            selected: active,
            onSelected: (_) => onSelected(tab),
            labelStyle: GoogleFonts.montserrat(
              fontSize: 10.5,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : AppColors.headingSlate,
            ),
            selectedColor: AppColors.accentBlue,
            backgroundColor: Theme.of(context).colorScheme.surface,
            side: BorderSide(
              color: active ? AppColors.accentBlue : AppColors.divider,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 2),
            visualDensity: VisualDensity.compact,
          );
        },
      ),
    );
  }
}

class _ComposerCard extends StatelessWidget {
  final VoidCallback onOpen;

  const _ComposerCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onOpen,
      borderRadius: BorderRadius.circular(AppRadius.sharp),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.sharp),
        ),
        child: Row(
          children: [
            Icon(
              Icons.edit_note_rounded,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.55),
              size: 22,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                "What's happening in the built environment?",
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                ),
              ),
            ),
            const Icon(
              Icons.edit_rounded,
              color: AppColors.captionSlate,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}

class _NativeTimeline extends StatelessWidget {
  final FeedController controller;
  final VoidCallback onOpenWebsite;

  const _NativeTimeline({
    required this.controller,
    required this.onOpenWebsite,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value && controller.items.isEmpty) {
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 30),
          child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
        );
      }
      if (controller.errorMessage.value != null && controller.items.isEmpty) {
        return _FeedStateCard(
          icon: Icons.cloud_off_rounded,
          title: 'Could not load the Feed',
          message: controller.errorMessage.value!,
          actionLabel: 'Retry',
          onAction: controller.load,
        );
      }
      if (controller.items.isEmpty) {
        return _FeedStateCard(
          icon: Icons.dynamic_feed_outlined,
          title: 'No Feed posts yet',
          message: 'There are no eligible public Feed records on this page.',
          actionLabel: 'Open Feed on website',
          onAction: onOpenWebsite,
        );
      }
      return Column(
        children: [
          for (final item in controller.items) ...[
            _FeedCard(item: item, controller: controller),
            const SizedBox(height: 10),
          ],
          if (controller.errorMessage.value != null)
            _InlineFeedError(
              message: controller.errorMessage.value!,
              onRetry: controller.loadMore,
            ),
          if (controller.isLoadingMore.value)
            const Padding(
              padding: EdgeInsets.all(14),
              child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
            ),
        ],
      );
    });
  }
}

class _FeedCard extends StatelessWidget {
  final FeedItem item;
  final FeedController controller;
  const _FeedCard({required this.item, required this.controller});

  bool get _signedIn {
    try {
      return Get.find<MjengoAuthController>().isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  Future<void> _vote(BuildContext context, String type) async {
    if (!_signedIn) {
      Get.toNamed(AppRoutes.login, arguments: {'returnTo': AppRoutes.feed});
      return;
    }
    try {
      await controller.vote(item, type);
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    }
  }

  Future<void> _openSource(BuildContext context) async {
    final source = item.source;
    if (source == null) return;
    if (source.articleSlug != null) {
      Get.toNamed(AppRoutes.articleDetail, arguments: source.articleSlug);
      return;
    }
    if (source.projectSlug != null) {
      Get.toNamed(AppRoutes.projectDetail, arguments: source.projectSlug);
      return;
    }
    if (source.incidentSlug != null) {
      Get.toNamed(AppRoutes.incidentDetail, arguments: source.incidentSlug);
      return;
    }
    final raw = source.canonicalUrl ?? item.canonicalUrl;
    final uri = raw == null ? null : Uri.tryParse(raw);
    if (uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty) {
      await LinkLauncher.openLink(context, raw!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authorName =
        item.author.displayName ??
        (item.author.isEditorial ? 'Mjengo Hub' : 'Community member');
    final source = item.source;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NetImage(
                url: item.author.avatarUrl,
                width: 34,
                height: 34,
                fit: BoxFit.cover,
                borderRadius: BorderRadius.circular(17),
                errorBuilder: (_) => _InitialAvatar(name: authorName),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      authorName,
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _feedTime(item.publishedAt),
                      style: GoogleFonts.montserrat(
                        fontSize: 10,
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.62,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (item.reportPostId != null)
                FeedReportButton(
                  postId: item.reportPostId!,
                  authenticated: _signedIn,
                  onRequireAuth: () => Get.toNamed(
                    AppRoutes.login,
                    arguments: {'returnTo': AppRoutes.feed},
                  ),
                ),
            ],
          ),
          if (item.text != null) ...[
            const SizedBox(height: 12),
            Text(
              item.text!,
              style: GoogleFonts.montserrat(
                fontSize: 13,
                height: 1.5,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
          if (item.media.isNotEmpty) ...[
            const SizedBox(height: 10),
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: item.media.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, index) =>
                    _FeedMediaTile(media: item.media[index]),
              ),
            ),
          ],
          if (source != null &&
              (source.title != null || source.summary != null)) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => _openSource(context),
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest,
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(AppRadius.sharp),
                ),
                child: Row(
                  children: [
                    if (source.imageUrl != null)
                      NetImage(
                        url: source.imageUrl,
                        width: 46,
                        height: 46,
                        fit: BoxFit.cover,
                        borderRadius: BorderRadius.circular(AppRadius.sharp),
                      )
                    else
                      const Icon(
                        Icons.link_rounded,
                        color: AppColors.accentBlue,
                      ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            source.title ?? 'View linked source',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.montserrat(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                          if (source.summary != null)
                            Text(
                              source.summary!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.montserrat(
                                fontSize: 10,
                                color: theme.colorScheme.onSurface.withValues(
                                  alpha: 0.68,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: 18),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 8),
          FeedVoteBar(
            score: item.engagement?.netScore ?? 0,
            voteType: item.engagement?.voteType,
            authenticated: _signedIn,
            onVote: (type) => _vote(context, type),
            onRequireAuth: () => Get.toNamed(
              AppRoutes.login,
              arguments: {'returnTo': AppRoutes.feed},
            ),
          ),
          if (item.commentCount != null) ...[
            const SizedBox(height: 10),
            InkWell(
              onTap: () => Get.toNamed(
                AppRoutes.feedDiscussion,
                arguments: {'post': item},
              ),
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              child: Row(
                children: [
                  const Icon(
                    Icons.mode_comment_outlined,
                    size: 15,
                    color: AppColors.captionSlate,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    '${item.commentCount} comments',
                    style: GoogleFonts.montserrat(
                      fontSize: 10.5,
                      color: AppColors.captionSlate,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FeedMediaTile extends StatelessWidget {
  final FeedMedia media;
  const _FeedMediaTile({required this.media});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.sharp),
              child: media.url == null
                  ? Container(
                      color: AppColors.mutedCanvas,
                      alignment: Alignment.center,
                      child: const Icon(Icons.image_not_supported_outlined),
                    )
                  : NetImage(url: media.url, fit: BoxFit.contain),
            ),
          ),
          if (media.caption != null || media.credit != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                [
                  if (media.caption != null) media.caption!,
                  if (media.credit != null) '© ${media.credit}',
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(
                  fontSize: 9,
                  color: AppColors.captionSlate,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FeedStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  const _FeedStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppColors.accentBlue, size: 28),
          const SizedBox(height: 8),
          Text(
            title,
            style: GoogleFonts.montserrat(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 5),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(fontSize: 11.5),
          ),
          const SizedBox(height: 10),
          OutlinedButton(onPressed: onAction, child: Text(actionLabel)),
        ],
      ),
    );
  }
}

class _InlineFeedError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _InlineFeedError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(child: Text(message, style: const TextStyle(fontSize: 11))),
      TextButton(onPressed: onRetry, child: const Text('Retry')),
    ],
  );
}

class _InitialAvatar extends StatelessWidget {
  final String name;
  const _InitialAvatar({required this.name});

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: 17,
    backgroundColor: AppColors.accentBlue,
    child: Text(
      name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
      style: const TextStyle(color: Colors.white, fontSize: 12),
    ),
  );
}

String _feedTime(DateTime? value) {
  if (value == null) return 'Time unavailable';
  final delta = DateTime.now().difference(value.toLocal());
  if (delta.inMinutes < 1) return 'Just now';
  if (delta.inHours < 1) return '${delta.inMinutes}m ago';
  if (delta.inDays < 1) return '${delta.inHours}h ago';
  if (delta.inDays < 7) return '${delta.inDays}d ago';
  return '${value.day}/${value.month}/${value.year}';
}

class _TimelineUnavailable extends StatelessWidget {
  final FeedTab selectedTab;
  final VoidCallback onOpenWebsite;

  const _TimelineUnavailable({
    required this.selectedTab,
    required this.onOpenWebsite,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tabText = selectedTab == FeedTab.forYou
        ? 'The native timeline is not connected yet.'
        : '${selectedTab.label} is not available in the native app yet.';
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: AppColors.divider),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.dynamic_feed_outlined,
            color: AppColors.accentBlue,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            tabText,
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'The website Feed is the current authoritative source. '
            'A mobile Feed API is required before records can be rendered here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserrat(
              fontSize: 11.5,
              height: 1.45,
              color: theme.colorScheme.onSurface.withValues(alpha: 0.68),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onOpenWebsite,
            icon: const Icon(Icons.open_in_new_rounded, size: 16),
            label: const Text('Open Feed on website'),
          ),
        ],
      ),
    );
  }
}

class _MediaDirectoryCard extends StatelessWidget {
  final VoidCallback onOpen;
  const _MediaDirectoryCard({required this.onOpen});

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onOpen,
      icon: const Icon(Icons.perm_media_outlined, size: 18),
      label: const Text('Open Media Directory'),
      style: OutlinedButton.styleFrom(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        side: const BorderSide(color: AppColors.divider),
      ),
    );
  }
}
