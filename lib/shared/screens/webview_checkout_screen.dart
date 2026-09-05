// lib/shared/screens/webview_checkout_screen.dart
//
// In-app WebView for the existing session-based web checkout/verification
// flows (merch purchase, Prime verification). Loads the real
// mjengohub.co.ke page directly — there is no SSO token-handoff endpoint on
// the backend (POST /auth/webview-token doesn't exist), so this can't start
// pre-authenticated as the mobile user; the user signs in on the page itself
// if the site doesn't already have a browser session. Everything after that
// (cart, Paystack redirect, webhook) is the web app's own existing flow,
// untouched.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';

class WebviewCheckoutScreen extends StatefulWidget {
  final String title;

  /// Relative path on mjengohub.co.ke to open, e.g. '/merch' or '/verify'.
  final String nextPath;

  /// Called with the current URL on every navigation — return true to pop
  /// this screen (e.g. once the URL reaches an order confirmation or
  /// verification-success page). Optional; without it the user just backs
  /// out manually via the app bar.
  final bool Function(String url)? isSuccessUrl;
  final VoidCallback? onSuccess;

  const WebviewCheckoutScreen({
    super.key,
    required this.title,
    required this.nextPath,
    this.isSuccessUrl,
    this.onSuccess,
  });

  @override
  State<WebviewCheckoutScreen> createState() => _WebviewCheckoutScreenState();
}

class _WebviewCheckoutScreenState extends State<WebviewCheckoutScreen> {
  static const _baseUrl = 'https://mjengohub.co.ke';
  WebViewController? _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    final controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (currentUrl) {
          if (!mounted) return;
          setState(() => _loading = false);
          if (widget.isSuccessUrl?.call(currentUrl) == true) {
            widget.onSuccess?.call();
            Get.back();
          }
        },
      ))
      ..loadRequest(Uri.parse('$_baseUrl${widget.nextPath}'));
    _controller = controller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title,
            style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.headingSlate)),
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_loading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
