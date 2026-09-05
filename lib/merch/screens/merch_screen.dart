// lib/merch/screens/merch_screen.dart
//
// Merch catalog (read-only — `GET /merch/products`), Buyer Shoutouts
// embedded directly below it, and the dual weekly leaderboard preview below
// that. "Buy" opens the existing web `/merch` cart+checkout flow in an
// in-app WebView via the SSO handoff (WebviewCheckoutScreen) — there's no
// native cart, the web app owns that state entirely.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../news/widgets/net_image.dart';
import '../../shared/screens/webview_checkout_screen.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/leaderboard_widget.dart';
import '../../shared/widgets/responsive.dart';
import '../../shared/widgets/scroll_to_top_fab.dart';
import '../models/merch_model.dart';
import '../services/merch_service.dart';

class MerchScreen extends StatefulWidget {
  const MerchScreen({super.key});

  @override
  State<MerchScreen> createState() => _MerchScreenState();
}

class _MerchScreenState extends State<MerchScreen> {
  final _service = MerchService();
  final _scrollController = ScrollController();
  List<MerchProduct> _products = [];
  List<MerchShoutout> _shoutouts = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final results = await Future.wait([_service.getProducts(), _service.getShoutouts(limit: 10)]);
    if (!mounted) return;
    setState(() {
      _products = results[0] as List<MerchProduct>;
      _shoutouts = results[1] as List<MerchShoutout>;
      _loading = false;
    });
  }

  void _openCheckout() {
    Get.to(() => const WebviewCheckoutScreen(title: 'Mjengo Hub Merch', nextPath: '/merch'));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Merch', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      ),
      body: ScrollToTopFab(
        controller: _scrollController,
        child: ContentWidth(
        maxWidth: 900,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  children: [
                    if (_products.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
                        child: Center(
                          child: Text('No merch available right now.', style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle)),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 0.72,
                          ),
                          itemCount: _products.length,
                          itemBuilder: (_, i) => _ProductCard(product: _products[i], onBuy: _openCheckout),
                        ),
                      ),

                    // ── Buyer Shoutouts — embedded directly in the feed ──
                    if (_shoutouts.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text('Buyer Shoutouts', style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemCount: _shoutouts.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (_, i) => _ShoutoutCard(shoutout: _shoutouts[i]),
                        ),
                      ),
                    ],

                    // ── Dual weekly leaderboards ─────────────────────────
                    const SizedBox(height: 24),
                    const LeaderboardPreview(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
      ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final MerchProduct product;
  final VoidCallback onBuy;
  const _ProductCard({required this.product, required this.onBuy});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.divider)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(aspectRatio: 1, child: NetImage(url: product.image, fit: BoxFit.cover, placeholderColor: const Color(0xFF1E3A5F))),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(product.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                const SizedBox(height: 4),
                Text('KSh ${product.price.toStringAsFixed(0)}',
                    style: GoogleFonts.montserrat(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.accentBlue)),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: product.isInStock ? onBuy : null,
                    style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 8)),
                    child: Text(product.isInStock ? 'Buy' : 'Out of stock', style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w500)),
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

class _ShoutoutCard extends StatelessWidget {
  final MerchShoutout shoutout;
  const _ShoutoutCard({required this.shoutout});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.divider)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipOval(
                child: SizedBox(width: 22, height: 22, child: NetImage(url: shoutout.userAvatar, fit: BoxFit.cover, placeholderColor: const Color(0xFF1E3A5F))),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(shoutout.userName ?? 'A buyer', maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textDark)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Expanded(
            child: Text(shoutout.message ?? '', maxLines: 3, overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserrat(fontSize: 11, color: AppColors.textSubtle, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
