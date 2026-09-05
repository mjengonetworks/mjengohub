// lib/news/screens/submit_article_screen.dart
//
// Article submission — gated strictly behind Mjengo Hub Prime
// (`user.isVerified`/`isPrime`), matching api.py's `POST /articles` server-
// side check. `SubmitArticleScreen.open()` is the entry point every call
// site should use: it shows the Prime-required modal for non-Prime users
// instead of the form, so the gate can never be bypassed by deep-linking
// into the screen directly.
import 'package:flutter/material.dart';
import 'package:flutter_quill/flutter_quill.dart' as quill;
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vsc_quill_delta_to_html/vsc_quill_delta_to_html.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../shared/screens/webview_checkout_screen.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/responsive.dart';
import '../models/category_model.dart';
import '../services/news_api_service.dart';

class SubmitArticleScreen extends StatefulWidget {
  const SubmitArticleScreen({super.key});

  /// Entry point for every "Submit an Article" affordance in the app —
  /// checks Prime status first and shows the explainer modal instead of the
  /// form when the user isn't verified.
  static void open(BuildContext context) {
    final auth = Get.find<MjengoAuthController>();
    if (!auth.isAuthenticated) {
      Get.snackbar('Sign in required', 'Sign in to submit an article.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    if (auth.currentUser?.isPrime != true) {
      _showPrimeRequiredModal(context);
      return;
    }
    Get.to(() => const SubmitArticleScreen());
  }

  static void _showPrimeRequiredModal(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(18))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: AppColors.primeBadge.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: const Icon(Icons.workspace_premium_rounded, color: AppColors.primeBadge, size: 28),
            ),
            const SizedBox(height: 16),
            Text('Mjengo Hub Prime required', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark)),
            const SizedBox(height: 8),
            Text(
              'Article submissions are reserved for Prime members so we can keep editorial quality high. '
              'Upgrade to Prime to submit articles for review.',
              textAlign: TextAlign.center,
              style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle, height: 1.5),
            ),
            const SizedBox(height: 20),
            AppSubmitButton(
              label: 'Get Verified',
              busy: false,
              onPressed: () {
                Navigator.of(context).pop();
                Get.to(() => const WebviewCheckoutScreen(title: 'Mjengo Hub Prime', nextPath: '/verify'));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  State<SubmitArticleScreen> createState() => _SubmitArticleScreenState();
}

class _SubmitArticleScreenState extends State<SubmitArticleScreen> {
  final _service = NewsApiService();
  final _formKey = GlobalKey<FormState>();
  final _title = TextEditingController();
  final _summary = TextEditingController();
  final _contentController = quill.QuillController.basic();

  List<Category> _categories = [];
  String? _categorySlug;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _service.getCategories().then((cats) {
      if (mounted) setState(() => _categories = cats);
    });
  }

  @override
  void dispose() {
    _title.dispose();
    _summary.dispose();
    _contentController.dispose();
    super.dispose();
  }

  String _contentHtml() {
    final ops = _contentController.document.toDelta().toJson();
    if (ops.isEmpty) return '';
    return QuillDeltaToHtmlConverter(
      List<Map<String, dynamic>>.from(ops.map((o) => Map<String, dynamic>.from(o as Map))),
      ConverterOptions.forEmail(),
    ).convert();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final html = _contentHtml();
    if (html.trim().isEmpty) {
      Get.snackbar('Content required', 'Please write your article before submitting.', snackPosition: SnackPosition.BOTTOM);
      return;
    }
    setState(() => _submitting = true);

    final res = await _service.submitArticle(
      title: _title.text.trim(),
      content: html,
      summary: _summary.text.trim(),
      categorySlug: _categorySlug,
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      Get.back();
      Get.snackbar('Submitted', res['message'] as String? ?? 'Article submitted for editorial review',
          backgroundColor: AppColors.success, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
    } else {
      Get.snackbar('Could not submit', res['message'] as String? ?? 'Please try again.',
          backgroundColor: AppColors.danger, colorText: Colors.white, snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(12));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('Submit an Article', style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w500, color: AppColors.textDark)),
      ),
      body: ContentWidth(
        maxWidth: 700,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Submissions go to our editorial team for review before they\'re published.',
                style: GoogleFonts.montserrat(fontSize: 12.5, height: 1.5, color: AppColors.textSubtle),
              ),
              const SizedBox(height: 20),

              const FieldLabel('Title', required: true),
              AppTextField(controller: _title, hint: 'Article headline', validator: (v) => requiredField(v, 'Title')),
              const SizedBox(height: 14),

              const FieldLabel('Category'),
              AppDropdown<String>(
                value: _categorySlug,
                items: _categories.map((c) => c.slug).toList(),
                labelOf: (slug) => _categories.firstWhere((c) => c.slug == slug).name,
                hint: 'Select a category (optional)',
                onChanged: (v) => setState(() => _categorySlug = v),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Summary'),
              AppTextField(controller: _summary, hint: 'A one- or two-sentence summary (optional)', maxLines: 2),
              const SizedBox(height: 14),

              const FieldLabel('Content', required: true),
              Container(
                decoration: BoxDecoration(border: Border.all(color: AppColors.divider), borderRadius: BorderRadius.circular(10)),
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    quill.QuillSimpleToolbar(
                      controller: _contentController,
                      config: const quill.QuillSimpleToolbarConfig(
                        showFontFamily: false,
                        showFontSize: false,
                        showSubscript: false,
                        showSuperscript: false,
                        showSearchButton: false,
                        showBackgroundColorButton: false,
                        showColorButton: false,
                        multiRowsDisplay: false,
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                    SizedBox(
                      height: 260,
                      child: quill.QuillEditor.basic(
                        controller: _contentController,
                        config: const quill.QuillEditorConfig(padding: EdgeInsets.all(10), placeholder: 'Write your article…'),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),
              AppSubmitButton(label: 'Submit for review', busy: _submitting, onPressed: _submit),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
