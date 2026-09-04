// lib/shared/screens/webview_checkout_screen.dart
//
// In-app WebView for the existing session-based web checkout/verification
// flows (merch purchase, Prime verification) — opened with a short-lived
// SSO handoff token (WebviewCheckoutService) so the WebView starts already
// signed in as the mobile user. Everything after that (cart, Paystack
// redirect, webhook) is the web app's own existing flow, untouched.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../theme/app_theme.dart';
import '../services/webview_checkout_service.dart';

class WebviewCheckoutScreen extends StatefulWidget {
  final String title;

  /// Relative path on mjengohub.co.ke to open after the handoff, e.g.
  /// '/merch' or '/verify'.
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
  final _service = WebviewCheckoutService();
  WebViewController? _controller;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final url = await _service.getHandoffUrl(widget.nextPath);
    if (!mounted) return;
    if (url == null) {
      setState(() {
        _loading = false;
        _failed = true;
      });
      return;
    }

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
      ..loadRequest(Uri.parse(url));

    setState(() => _controller = controller);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(widget.title, style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark)),
      ),
      body: Stack(
        children: [
          if (_controller != null) WebViewWidget(controller: _controller!),
          if (_loading) const Center(child: CircularProgressIndicator()),
          if (_failed)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.textSubtle),
                    const SizedBox(height: 12),
                    Text('Could not open this page. Please try again.',
                        textAlign: TextAlign.center, style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
