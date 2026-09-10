// lib/navigation/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/home_screen.dart';
import '../news/screens/discover_screen.dart';
import '../videos/screens/videos_screen.dart';
import '../hub/screens/hub_screen.dart';
import '../profile/profile_screen.dart';
import '../shared/theme/app_theme.dart';
import 'app_header.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({super.key});

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(MainNavController(), permanent: true);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        body: Column(
          children: [
            const AppHeader(),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1080),
                  child: Obx(
                    () => IndexedStack(
                      index: ctrl.currentIndex.value,
                      children: const [
                        HomeScreen(), // MainNavController.tabHome
                        DiscoverScreen(), // MainNavController.tabNews
                        HubScreen(), // MainNavController.tabHub
                        VideosScreen(), // MainNavController.tabMedia
                        ProfileScreen(), // MainNavController.tabProfile
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Obx(
          () => _BottomNav(
            currentIndex: ctrl.currentIndex.value,
            onTap: (i) => ctrl.currentIndex.value = i,
          ),
        ),
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  // Order matches MainNavController.tabHome/tabNews/tabHub/tabMedia/tabProfile.
  static const _items = [
    _NavData(
      activeIcon: Icons.home_rounded,
      inactiveIcon: Icons.home_outlined,
      label: 'Home',
    ),
    _NavData(
      activeIcon: Icons.article_rounded,
      inactiveIcon: Icons.article_outlined,
      label: 'News',
    ),
    _NavData(
      activeIcon: Icons.hub_rounded,
      inactiveIcon: Icons.hub_outlined,
      label: 'Hub',
    ),
    _NavData(
      activeIcon: Icons.play_circle_filled_rounded,
      inactiveIcon: Icons.play_circle_outline_rounded,
      label: 'Media',
    ),
    _NavData(
      activeIcon: Icons.person_rounded,
      inactiveIcon: Icons.person_outline_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 68,
          child: Row(
            children: List.generate(
              _items.length,
              (i) => _NavItem(
                data: _items[i],
                isSelected: currentIndex == i,
                onTap: () => onTap(i),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav data ──────────────────────────────────────────────────────────────────

class _NavData {
  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;

  const _NavData({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
  });
}

// ── Nav item — active state gets a soft pill behind the icon ──────────────────

class _NavItem extends StatelessWidget {
  final _NavData data;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? AppColors.primaryBlue : const Color(0xFF94A3B8);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              height: 28,
              alignment: Alignment.center,
              child: Icon(
                isSelected ? data.activeIcon : data.inactiveIcon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              data.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.montserrat(
                fontSize: 10.5,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryBlue : Colors.transparent,
                shape: BoxShape.circle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MainNavController extends GetxController {
  // Named tab indices — use these instead of magic numbers when jumping
  // tabs from elsewhere in the app (Home/Hub sections, category tiles, …).
  static const int tabHome = 0;
  static const int tabNews = 1;
  static const int tabHub = 2;
  static const int tabMedia = 3;
  static const int tabProfile = 4;

  final RxInt currentIndex = 0.obs;
}
