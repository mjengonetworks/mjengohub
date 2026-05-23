// lib/home/home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../news/controllers/home_news_controller.dart';
import '../news/models/article_model.dart';
import '../news/widgets/featured_article_card.dart';
import '../news/widgets/breaking_news_card.dart';
import '../point/routes/app_routes.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl = Get.find<HomeNewsController>();
    final topPad = MediaQuery.of(context).padding.top;
    final screenH = MediaQuery.of(context).size.height;

    // Hero height = 48 % of screen, clamped for small / large phones
    final heroH = (screenH * 0.48).clamp(280.0, 420.0);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Obx(() {
        if (ctrl.isLoading.value) {
          return _loadingState(heroH, topPad);
        }
        if (ctrl.errorMessage.isNotEmpty &&
            ctrl.featuredArticles.isEmpty &&
            ctrl.breakingNews.isEmpty) {
          return _errorState(ctrl);
        }
        return _content(context, ctrl, heroH, topPad);
      }),
    );
  }

  // ── Main content ────────────────────────────────────────────────────────────

  Widget _content(
    BuildContext context,
    HomeNewsController ctrl,
    double heroH,
    double topPad,
  ) {
    return Column(
      children: [
        // ── Featured hero (fixed height, no scroll) ──────────────────────
        SizedBox(
          height: heroH,
          child: Stack(
            children: [
              // PageView of featured articles
              Obx(() => PageView.builder(
                    itemCount: ctrl.featuredArticles.length,
                    onPageChanged: ctrl.onPageChanged,
                    itemBuilder: (_, i) {
                      final article = ctrl.featuredArticles[i];
                      return FeaturedArticleCard(
                        article: article,
                        onTap: () => _openArticle(article),
                      );
                    },
                  )),

              // Hamburger icon (top-left, floating over image)
              Positioned(
                top: topPad + 8,
                left: 16,
                child: _hamburgerButton(context),
              ),

              // Page dot indicators (bottom-right of hero)
              Positioned(
                bottom: 30,
                right: 20,
                child: Obx(() => ctrl.featuredArticles.length > 1
                    ? PageDotIndicator(
                        count: ctrl.featuredArticles.length,
                        current: ctrl.featuredIndex.value,
                      )
                    : const SizedBox.shrink()),
              ),
            ],
          ),
        ),

        // ── Breaking News section ────────────────────────────────────────
        Expanded(
          child: Container(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                _breakingHeader(ctrl),
                const SizedBox(height: 14),
                Expanded(child: _breakingList(ctrl)),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Breaking News header ────────────────────────────────────────────────────

  Widget _breakingHeader(HomeNewsController ctrl) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Breaking News',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
            ),
          ),
          GestureDetector(
            onTap: () {
              // Navigate to discover tab — handled by MainNavController
              final navCtrl = Get.find<MainNavController>();
              navCtrl.currentIndex.value = 1;
            },
            child: Text(
              'More',
              style: GoogleFonts.montserrat(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Breaking News horizontal list ───────────────────────────────────────────

  Widget _breakingList(HomeNewsController ctrl) {
    return Obx(() {
      if (ctrl.breakingNews.isEmpty) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'No breaking news at the moment.',
            style: GoogleFonts.montserrat(
                fontSize: 13, color: const Color(0xFF9CA3AF)),
          ),
        );
      }
      return ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: ctrl.breakingNews.length,
        itemBuilder: (_, i) {
          final article = ctrl.breakingNews[i];
          return BreakingNewsCard(
            article: article,
            onTap: () => _openArticle(article),
          );
        },
      );
    });
  }

  // ── Hamburger button ────────────────────────────────────────────────────────

  Widget _hamburgerButton(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: IconButton(
        padding: EdgeInsets.zero,
        icon: const Icon(Icons.menu_rounded, color: Colors.white, size: 22),
        onPressed: () => Scaffold.of(context).openDrawer(),
      ),
    );
  }

  // ── Loading state ────────────────────────────────────────────────────────────

  Widget _loadingState(double heroH, double topPad) {
    return Column(
      children: [
        Container(height: heroH, color: const Color(0xFF1F2937)),
        const Expanded(
          child: Center(
            child: CircularProgressIndicator(
              valueColor:
                  AlwaysStoppedAnimation<Color>(Color(0xFF111827)),
              strokeWidth: 2,
            ),
          ),
        ),
      ],
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────────

  Widget _errorState(HomeNewsController ctrl) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded,
                size: 52, color: Color(0xFFD1D5DB)),
            const SizedBox(height: 16),
            Text(
              ctrl.errorMessage.value,
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(
                  fontSize: 14, color: const Color(0xFF6B7280)),
            ),
            const SizedBox(height: 20),
            TextButton(
              onPressed: ctrl.fetchHomeData,
              child: Text('Retry',
                  style: GoogleFonts.montserrat(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  void _openArticle(Article article) {
    Get.toNamed(AppRoutes.articleDetail, arguments: article.slug);
  }
}

// MainNavController is defined here for convenience (used by HomeScreen)
// and by MainNavigation.
class MainNavController extends GetxController {
  final currentIndex = 0.obs;
}
