// lib/projects/screens/post_update_screen.dart
//
// Progress update composer — shared between privileged roles (Admin/Editor/
// Moderator: "Add an Update", published immediately) and regular signed-in
// users ("Suggest an Update", max 300 words, lands in the review queue).
// Both hit the same `POST /projects/{id}/updates`; the server decides
// auto-approve vs. review-queue based on the caller's role, this screen
// just adapts its copy/word-cap to match.
//
// Prime tier guardrail: free users are capped client-side at 150 words / 3
// photos, Prime users get the full server-enforced 300 words / up to 10
// photos. Photo attachment itself is best-effort (see
// ProjectsService.uploadUpdateMedia) since the media endpoint for updates
// isn't confirmed live — the update text always posts regardless.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../shared/screens/webview_checkout_screen.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/form_fields.dart';
import '../../shared/widgets/responsive.dart';
import '../services/media_pipeline.dart';
import '../services/projects_service.dart';

const int kUpdateWordCap = 300;
const int kFreeUpdateWordCap = 150;
const int kFreePhotoCap = 3;
const int kPrimePhotoCap = 10;

class PostUpdateScreen extends StatefulWidget {
  final int projectId;
  final String projectTitle;

  /// True for Admin/Editor/Moderator — changes the title/CTA copy and
  /// success message; the 300-word cap and review-queue behavior are
  /// server-enforced regardless of this flag, so getting it wrong here is
  /// cosmetic only, not a way to bypass moderation.
  final bool isPrivileged;

  const PostUpdateScreen({
    super.key,
    required this.projectId,
    required this.projectTitle,
    required this.isPrivileged,
  });

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
  final List<PickedMedia> _photos = [];
  bool _showUpgradeBanner = false;

  bool get _isPrime =>
      Get.find<MjengoAuthController>().currentUser?.isPrime == true;
  int get _wordCap => _isPrime ? kUpdateWordCap : kFreeUpdateWordCap;
  int get _photoCap => _isPrime ? kPrimePhotoCap : kFreePhotoCap;

  @override
  void initState() {
    super.initState();
    _content.addListener(() {
      final count = _content.text.trim().isEmpty
          ? 0
          : _content.text.trim().split(RegExp(r'\s+')).length;
      setState(() {
        _wordCount = count;
        if (!_isPrime && count > kFreeUpdateWordCap) _showUpgradeBanner = true;
      });
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
    if (text.split(RegExp(r'\s+')).length > _wordCap) {
      return _isPrime
          ? 'Keep it under $_wordCap words'
          : 'Free accounts are capped at $_wordCap words — upgrade to Prime for $kUpdateWordCap';
    }
    return null;
  }

  Future<void> _addPhotos() async {
    if (_photos.length >= _photoCap) {
      setState(() => _showUpgradeBanner = !_isPrime);
      return;
    }
    final picked = await MediaPipeline.pickMultiple(imagesOnly: true);
    if (picked.isEmpty) return;
    setState(() {
      final room = _photoCap - _photos.length;
      _photos.addAll(picked.take(room));
      if (!_isPrime && picked.length > room) _showUpgradeBanner = true;
    });
  }

  void _removePhoto(int index) => setState(() => _photos.removeAt(index));

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);

    final res = await _service.postProjectUpdate(
      projectId: widget.projectId,
      content: _content.text.trim(),
      externalVideoUrl: _videoUrl.text.trim(),
    );

    if (res['success'] == true) {
      final updateId = res['updateId'] as int?;
      if (updateId != null && _photos.isNotEmpty) {
        for (final photo in _photos) {
          await _service.uploadUpdateMedia(
            projectId: widget.projectId,
            updateId: updateId,
            bytes: photo.bytes,
            filename: photo.filename,
          );
        }
      }
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    if (res['success'] == true) {
      Get.back(result: true);
      Get.snackbar(
        widget.isPrivileged ? 'Published' : 'Submitted',
        res['message'] as String? ??
            (widget.isPrivileged
                ? 'Update published'
                : 'Update submitted for review'),
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
    final over = _wordCount > _wordCap;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isPrivileged ? 'Add an Update' : 'Suggest an Update',
          style: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: AppColors.textDark,
          ),
        ),
      ),
      body: ContentWidth(
        maxWidth: 700,
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                widget.projectTitle,
                style: GoogleFonts.montserrat(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.isPrivileged
                    ? 'This publishes immediately as an official update.'
                    : 'Your update goes into a review queue before it\'s shown publicly.',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  color: AppColors.textSubtle,
                ),
              ),
              const SizedBox(height: 20),

              const FieldLabel('Update', required: true),
              AppTextField(
                controller: _content,
                hint: 'What\'s new on this project?',
                maxLines: 8,
                validator: _validateContent,
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    '$_wordCount / $_wordCap words',
                    style: GoogleFonts.montserrat(
                      fontSize: 11,
                      color: over ? AppColors.danger : AppColors.textSubtle,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              const FieldLabel('Reference video link'),
              AppTextField(
                controller: _videoUrl,
                hint: 'YouTube link (optional)',
                keyboard: TextInputType.url,
              ),
              const SizedBox(height: 14),

              FieldLabel('Photos (${_photos.length}/$_photoCap)'),
              _PhotoPicker(
                photos: _photos,
                onAdd: _addPhotos,
                onRemove: _removePhoto,
              ),

              if (_showUpgradeBanner) ...[
                const SizedBox(height: 14),
                _PrimeUpgradeBanner(
                  onDismiss: () => setState(() => _showUpgradeBanner = false),
                ),
              ],

              const SizedBox(height: 24),
              AppSubmitButton(
                label: widget.isPrivileged
                    ? 'Publish update'
                    : 'Submit for review',
                busy: _submitting,
                onPressed: _submit,
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _PhotoPicker extends StatelessWidget {
  final List<PickedMedia> photos;
  final VoidCallback onAdd;
  final void Function(int) onRemove;
  const _PhotoPicker({
    required this.photos,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (int i = 0; i < photos.length; i++)
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.sharp),
                child: Image.memory(
                  photos[i].bytes,
                  width: 72,
                  height: 72,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                top: 2,
                right: 2,
                child: GestureDetector(
                  onTap: () => onRemove(i),
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.black54,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        GestureDetector(
          onTap: onAdd,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.borderSlate),
              borderRadius: BorderRadius.circular(AppRadius.sharp),
            ),
            child: const Icon(
              Icons.add_a_photo_outlined,
              color: AppColors.textSubtle,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrimeUpgradeBanner extends StatelessWidget {
  final VoidCallback onDismiss;
  const _PrimeUpgradeBanner({required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.headingSlate.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
        border: Border.all(color: AppColors.borderSlate),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.workspace_premium_outlined,
            size: 18,
            color: AppColors.headingSlate,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Mjengo Hub Prime members get $kUpdateWordCap words and $kPrimePhotoCap photos per update.',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                color: AppColors.headingSlate,
                height: 1.4,
              ),
            ),
          ),
          TextButton(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 0),
            ),
            onPressed: () => Get.to(
              () => const WebviewCheckoutScreen(
                title: 'Get Verified',
                nextPath: '/verify',
              ),
            ),
            child: Text(
              'Upgrade',
              style: GoogleFonts.montserrat(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.headingSlate,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDismiss,
            child: const Icon(
              Icons.close_rounded,
              size: 16,
              color: AppColors.textSubtle,
            ),
          ),
        ],
      ),
    );
  }
}
