// lib/feed/screens/feed_screen.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../point/routes/app_routes.dart';
import '../../shared/services/link_launcher.dart';
import '../../shared/theme/app_theme.dart';
import '../models/feed_contract.dart';

/// Native Media & Feed foundation.
///
/// The website's /feed page is currently HTML/session based. Until a
/// mobile-compatible JSON read/write contract is deployed, this screen keeps
/// the native information architecture visible and routes the real Feed to
/// the website instead of fabricating timeline records.
class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});

  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  FeedTab _selectedTab = FeedTab.forYou;

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
        onRefresh: () async {},
        child: ListView(
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
            const _ComposerPlaceholder(),
            const SizedBox(height: 12),
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

class _ComposerPlaceholder extends StatelessWidget {
  const _ComposerPlaceholder();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
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
            Icons.lock_outline_rounded,
            color: AppColors.captionSlate,
            size: 16,
          ),
        ],
      ),
    );
  }
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
