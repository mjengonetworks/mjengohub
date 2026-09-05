import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../point/routes/app_routes.dart';

const Color _primary     = Color(0xFF3B82F6);
const Color _primaryDeep = Color(0xFF1D4ED8);
const Color _textDark    = Color(0xFF111827);
const Color _textGray    = Color(0xFF475569);

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardPage> _pages = [
    _OnboardPage(
      image: 'assets/onboard/onboard.jpg',
      title: 'Kenya\'s Construction Hub',
      subtitle:
          'Stay ahead with expert articles, project insights, and industry news — everything a builder, contractor, or investor needs in one place.',
    ),
    _OnboardPage(
      image: 'assets/onboard/onboardtwo.jpg',
      title: 'Find Verified Professionals',
      subtitle:
          'Browse vetted fundis, contractors, and suppliers by trade and location. Blue-badge verified. Rated by the community. Hire with confidence.',
    ),
    _OnboardPage(
      image: 'assets/onboard/onboardthree.jpg',
      title: 'Track Kenya\'s Development',
      subtitle:
          'Follow roads, housing, water, and energy projects on a live map. Submit updates from the ground. See your country being built in real time.',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  void _completeOnboarding() => Get.offAllNamed(AppRoutes.login);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final topPadding = MediaQuery.of(context).padding.top;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final isLast = _currentPage == _pages.length - 1;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // ── Paged content ────────────────────────────────────────────
          PageView.builder(
            controller: _pageController,
            itemCount: _pages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (_, index) => _OnboardPageView(
              page: _pages[index],
              blobHeight: size.height * 0.52,
            ),
          ),

          // ── Skip (top-right) ─────────────────────────────────────────
          if (!isLast)
            Positioned(
              top: topPadding + 12,
              right: 20,
              child: GestureDetector(
                onTap: _completeOnboarding,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Skip',
                    style: GoogleFonts.montserrat(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),

          // ── Bottom controls ──────────────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomPadding + 28,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? _primary : const Color(0xFFBFDBFE),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 28),

                // Next / Get Started button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _nextPage,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primary,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: Text(
                        isLast ? 'Get Started' : 'Next',
                        style: GoogleFonts.montserrat(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Single onboarding page ───────────────────────────────────────────────────

class _OnboardPageView extends StatelessWidget {
  final _OnboardPage page;
  final double blobHeight;
  const _OnboardPageView({required this.page, required this.blobHeight});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Blue blob with image inside
        SizedBox(
          height: blobHeight,
          width: double.infinity,
          child: Stack(
            children: [
              // Blue gradient blob background
              Positioned.fill(
                child: ClipPath(
                  clipper: _BlobClipper(),
                  child: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                  ),
                ),
              ),
              // Image clipped to same blob shape
              Positioned.fill(
                child: ClipPath(
                  clipper: _BlobClipper(),
                  child: Image.asset(
                    page.image,
                    fit: BoxFit.cover,
                    color: Colors.blue.withOpacity(0.18),
                    colorBlendMode: BlendMode.srcATop,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Text content
        Padding(
          padding: const EdgeInsets.fromLTRB(28, 32, 28, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                page.title,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: _textDark,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                page.subtitle,
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: _textGray,
                  height: 1.65,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─── Blob clipper (same shape as auth screens) ────────────────────────────────

class _BlobClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height * 0.78);
    path.cubicTo(
      size.width * 0.10, size.height * 0.95,
      size.width * 0.30, size.height * 0.88,
      size.width * 0.50, size.height * 0.93,
    );
    path.cubicTo(
      size.width * 0.70, size.height * 0.98,
      size.width * 0.85, size.height * 0.80,
      size.width,        size.height * 0.88,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(_BlobClipper oldClipper) => false;
}

// ─── Data class ───────────────────────────────────────────────────────────────

class _OnboardPage {
  final String image;
  final String title;
  final String subtitle;
  const _OnboardPage({
    required this.image,
    required this.title,
    required this.subtitle,
  });
}
