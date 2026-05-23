// lib/navigation/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../home/home_screen.dart';
import '../news/screens/discover_screen.dart';
import '../profile/profile_screen.dart';

class MainNavigation extends StatelessWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // MainNavController defined in home_screen.dart — ensure it's available.
    final ctrl = Get.put(MainNavController(), permanent: true);

    return Scaffold(
      backgroundColor: Colors.white,
      // Each tab is kept alive via IndexedStack (no re-renders on tab switch)
      body: Obx(() => IndexedStack(
            index: ctrl.currentIndex.value,
            children: const [
              HomeScreen(),
              DiscoverScreen(),
              ProfileScreen(),
            ],
          )),

      // ── Bottom navigation bar ──────────────────────────────────────────
      bottomNavigationBar: Obx(() => _BottomNav(
            currentIndex: ctrl.currentIndex.value,
            onTap: (i) => ctrl.currentIndex.value = i,
          )),
    );
  }
}

class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF3F4F6), width: 1)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              _NavItem(
                icon: Icons.home_rounded,
                outlinedIcon: Icons.home_outlined,
                isSelected: currentIndex == 0,
                onTap: () => onTap(0),
              ),
              _NavItem(
                icon: Icons.search_rounded,
                outlinedIcon: Icons.search_rounded,
                isSelected: currentIndex == 1,
                onTap: () => onTap(1),
              ),
              _NavItem(
                icon: Icons.person_rounded,
                outlinedIcon: Icons.person_outline_rounded,
                isSelected: currentIndex == 2,
                onTap: () => onTap(2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData outlinedIcon;
  final bool isSelected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.outlinedIcon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          child: Center(
            child: Icon(
              isSelected ? icon : outlinedIcon,
              color:
                  isSelected ? const Color(0xFF111827) : const Color(0xFF9CA3AF),
              size: 26,
            ),
          ),
        ),
      ),
    );
  }
}
