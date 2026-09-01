// lib/navigation/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../home/home_screen.dart';
import '../news/screens/discover_screen.dart';
import '../videos/screens/videos_screen.dart';
import '../tools/tools_screen.dart';
import '../hub/screens/hub_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.put(MainNavController(), permanent: true);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: const Color(0xFFF0F4FF),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1080),
            child: Obx(() => IndexedStack(
                  index: ctrl.currentIndex.value,
                  children: const [
                    HomeScreen(),   // 0
                    HubScreen(),    // 1
                    DiscoverScreen(), // 2
                    VideosScreen(), // 3
                    ToolsScreen(),  // 4
                    ProfileScreen(), // 5
                  ],
                )),
          ),
        ),
        bottomNavigationBar: Obx(() => _BottomNav(
              currentIndex: ctrl.currentIndex.value,
              onTap: (i) => ctrl.currentIndex.value = i,
            )),
      ),
    );
  }
}

// ── Bottom navigation ─────────────────────────────────────────────────────────

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  static const Color _active   = Color(0xFF2563EB);
  static const Color _inactive = Color(0xFFAAAAAA);

  @override
  Widget build(BuildContext context) {
    const items = [
      _NavData(
        activeIcon: Icons.home_rounded,
        inactiveIcon: Icons.home_outlined,
        label: 'Home',
      ),
      _NavData(
        activeIcon: Icons.hub_rounded,
        inactiveIcon: Icons.hub_outlined,
        label: 'Hub',
      ),
      _NavData(
        activeIcon: Icons.search_rounded,
        inactiveIcon: Icons.search_rounded,
        label: 'Discover',
      ),
      _NavData(
        activeIcon: Icons.play_circle_filled_rounded,
        inactiveIcon: Icons.play_circle_outline_rounded,
        label: 'Videos',
      ),
      _NavData(
        activeIcon: Icons.construction_rounded,
        inactiveIcon: Icons.construction_outlined,
        label: 'Tools',
      ),
      _NavData(
        activeIcon: Icons.settings_rounded,
        inactiveIcon: Icons.settings_outlined,
        label: 'Settings',
      ),
    ];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFEEEEF5), width: 0.8)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 12,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(
              items.length,
              (i) => _NavItem(
                data: items[i],
                isSelected: currentIndex == i,
                activeColor: _active,
                inactiveColor: _inactive,
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

// ── Nav item ──────────────────────────────────────────────────────────────────

class _NavItem extends StatelessWidget {
  final _NavData data;
  final bool isSelected;
  final Color activeColor;
  final Color inactiveColor;
  final VoidCallback onTap;

  const _NavItem({
    required this.data,
    required this.isSelected,
    required this.activeColor,
    required this.inactiveColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? data.activeIcon : data.inactiveIcon,
                key: ValueKey(isSelected),
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              data.label,
              style: GoogleFonts.montserrat(
                fontSize: 10.5,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class MainNavController extends GetxController {
  final RxInt currentIndex = 0.obs;
}

