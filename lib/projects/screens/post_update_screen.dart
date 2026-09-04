// lib/projects/screens/post_update_screen.dart
//
// Progress update composer — shared between privileged roles (Admin/Editor/
// Moderator: "Add an Update", published immediately) and regular signed-in
// users ("Suggest an Update", max 300 words, lands in the review queue).
// Both hit the same `POST /projects/{id}/updates`; the server decides
// auto-approve vs. review-queue based on the caller's role, this screen
// just adapts its copy/word-cap to match.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/responsive.dart';
import '../services/projects_service.dart';

const int kUpdateWordCap = 300;

class PostUpdateScreen extends StatefulWidget {
  final int projectId;
  final String projectTitle;

  /// True for Admin/Editor/Moderator — changes the title/CTA copy and
  /// success message; the 300-word cap and review-queue behavior are
  /// server-enforced regardless of this flag, so getting it wrong here is
  /// cosmetic only, not a way to bypass moderation.
  final bool isPrivileged;

  const PostUpdateScreen({super.key, required this.projectId, required this.projectTitle, required this.isPrivileged});

  @override
  State<PostUpdateScreen> createState() => _PostUpdateScreenState();
}

class _PostUpdateScreenState extends State<PostUpdateScreen> {
  final _service = ProjectsService();
  final _formKey = GlobalKey<FormState>();
  final _content = TextEditingController();
  final _videoUrl = TextEditingController();
  bool _submitting = false;
  int _wordCount = 0;

  @override
  void initState() {
    super.initState();
    _content.addListener(() {
      setState(() => _wordCount = _content.text.trim().isEmpty ? 0 : _content.text.trim().split(RegExp(r'\s+')).length);
    });
  }

  @override
  void dispose() {
    _content.dispose();
    _videoUrl.dispose();
    super.dispose();
  }

  String? _validateContent(String? v) {
    final text = (v ?? '').trim();
    if (text.isEmpty) return 'Update content is required';
    if (text.split(RegExp(r'\s+')).length > kUpdateWordCap) return 'Keep it under $kUpdateWordCap words';
    return null;
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final res = await _service.postProjectUpdate(
      projectId: widget.projectId,
      content: _content.text.trim(),
      externalVideoUrl: _videoUrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      Get.back(result: true);
      Get.snackbar(
        widget.isPrivileged ? 'Published' : 'Submitted',
        res['message'] as String? ?? (widget.isPrivileged ? 'Update published' : 'Update submitted for review'),
        backgroundColor: AppColors.success,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    } else {
      Get.snackbar(
        'Could not submit',
        res['message'] as String? ?? 'Please try again.',
        backgroundColor: AppColors.danger,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(12),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final over = _wordCount > kUpdateWordCap;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isPrivileged ? 'Add an Update' : 'Suggest an Update',
          style: GoogleFonts.montserrat(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.textDark),
        ),
      ),
      body: ContentWidth(
        maxWidth: 700,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(widget.projectTitle, style: GoogleFonts.montserrat(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textSubtle)),
              const SizedBox(height: 4),
              Text(
                widget.isPrivileged
                    ? 'This publishes immediately as an official update.'
                    : 'Your update goes into a review queue before it\'s shown publicly.',
                style: GoogleFonts.montserrat(fontSize: 12, color: AppColors.textSubtle),
              ),
              const SizedBox(height: 20),

              const FieldLabel('Update', required: true),
              AppTextField(controller: _content, hint: 'What\'s new on this project?', maxLines: 8, validator: _validateContent),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('$_wordCount / $kUpdateWordCap words',
                      style: GoogleFonts.montserrat(fontSize: 11, color: over ? AppColors.danger : AppColors.textSubtle)),
                ),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Reference video link'),
              AppTextField(controller: _videoUrl, hint: 'YouTube link (optional)', keyboard: TextInputType.url),

              const SizedBox(height: 24),
              AppSubmitButton(label: widget.isPrivileged ? 'Publish update' : 'Submit for review', busy: _submitting, onPressed: _submit),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
