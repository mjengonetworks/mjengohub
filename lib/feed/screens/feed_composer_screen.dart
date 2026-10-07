import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/feed_controller.dart';
import '../models/feed_model.dart';
import '../../shared/theme/app_theme.dart';

class FeedComposerScreen extends StatefulWidget {
  final FeedController controller;
  final List<FeedUploadAttachment> initialAttachments;

  const FeedComposerScreen({
    super.key,
    required this.controller,
    this.initialAttachments = const [],
  });

  @override
  State<FeedComposerScreen> createState() => _FeedComposerScreenState();
}

class _FeedComposerScreenState extends State<FeedComposerScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  final _picker = ImagePicker();
  final _attachments = <FeedUploadAttachment>[];
  String? _error;
  bool _submitting = false;
  bool _submittedForModeration = false;

  @override
  void initState() {
    super.initState();
    _attachments.addAll(widget.initialAttachments.take(4));
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _focusNode.requestFocus(),
    );
  }

  @override
  void dispose() {
    _textController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final content = _textController.text.trim();
    if (content.isEmpty) {
      setState(() => _error = 'Write something before posting.');
      return;
    }
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final result = await widget.controller.publishPost(
        content,
        attachments: List.unmodifiable(_attachments),
      );
      if (!mounted) return;
      if (result.isPublished) {
        widget.controller.insertPublished(result.item);
        Navigator.of(context).pop(true);
        return;
      }
      setState(() {
        _submittedForModeration = true;
        _submitting = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = error is Exception
            ? error.toString().replaceFirst('FeedApiException: ', '')
            : 'Could not publish your post. Please try again.';
      });
    }
  }

  Future<void> _pickMedia() async {
    if (_attachments.length >= 4) return;
    try {
      final picked = await _picker.pickMultiImage(imageQuality: 90);
      final remaining = 4 - _attachments.length;
      final selected = picked.take(remaining);
      final additions = <FeedUploadAttachment>[];
      for (final file in selected) {
        additions.add(
          FeedUploadAttachment(
            filename: file.name,
            bytes: await file.readAsBytes(),
          ),
        );
      }
      if (!mounted) return;
      setState(() {
        _attachments.addAll(additions);
        _error = null;
      });
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Could not select those images. Please try again.',
        );
      }
    }
  }

  void _removeMedia(int index) {
    setState(() => _attachments.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = _textController.text.trim();
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'New Feed post',
          style: GoogleFonts.montserrat(
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        leading: const BackButton(),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            Text(
              "What's happening in the built environment?",
              style: GoogleFonts.montserrat(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 12),
            if (_submittedForModeration)
              _ComposerNotice(
                icon: Icons.hourglass_top_rounded,
                message: 'Your post was submitted and is awaiting moderation.',
                color: AppColors.accentBlue,
              ),
            if (_error != null) ...[
              _ComposerNotice(
                icon: Icons.error_outline_rounded,
                message: _error!,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 10),
            ],
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: _submitting || _submittedForModeration
                      ? null
                      : _pickMedia,
                  icon: const Icon(
                    Icons.add_photo_alternate_outlined,
                    size: 17,
                  ),
                  label: Text(
                    'Add media',
                    style: GoogleFonts.montserrat(fontSize: 11.5),
                  ),
                ),
                const SizedBox(width: 9),
                Text(
                  '${_attachments.length}/4 images',
                  style: GoogleFonts.montserrat(
                    fontSize: 10.5,
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
                  ),
                ),
              ],
            ),
            if (_attachments.isNotEmpty) ...[
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (var index = 0; index < _attachments.length; index++)
                    _AttachmentPreview(
                      attachment: _attachments[index],
                      onRemove: _submitting || _submittedForModeration
                          ? null
                          : () => _removeMedia(index),
                    ),
                ],
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _textController,
              focusNode: _focusNode,
              enabled: !_submitting && !_submittedForModeration,
              minLines: 6,
              maxLines: 10,
              maxLength: 100000,
              onChanged: (_) => setState(() {
                if (_error != null) _error = null;
              }),
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText:
                    'Share a construction, infrastructure or safety update.',
                hintStyle: GoogleFonts.montserrat(fontSize: 13),
                alignLabelWithHint: true,
                filled: true,
                fillColor: theme.colorScheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sharp),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.sharp),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
              style: GoogleFonts.montserrat(fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 8),
            Text(
              'Images use the existing Feed media storage and validation path. Video attachments are not available in the mobile composer yet.',
              style: GoogleFonts.montserrat(
                fontSize: 10.5,
                height: 1.35,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.62),
              ),
            ),
            const SizedBox(height: 18),
            SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed:
                    content.isEmpty || _submitting || _submittedForModeration
                    ? null
                    : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.accentBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.sharp),
                  ),
                ),
                child: _submitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Publish post',
                        style: GoogleFonts.montserrat(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ComposerNotice extends StatelessWidget {
  final IconData icon;
  final String message;
  final Color color;

  const _ComposerNotice({
    required this.icon,
    required this.message,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(AppRadius.sharp),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: GoogleFonts.montserrat(fontSize: 11.5, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentPreview extends StatelessWidget {
  final FeedUploadAttachment attachment;
  final VoidCallback? onRemove;

  const _AttachmentPreview({required this.attachment, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Container(
          width: 142,
          height: 112,
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            border: Border.all(color: AppColors.divider),
            borderRadius: BorderRadius.circular(AppRadius.sharp),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.sharp),
            child: Image.memory(
              Uint8List.fromList(attachment.bytes),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: AppColors.captionSlate,
              ),
            ),
          ),
        ),
        if (onRemove != null)
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: InkWell(
                onTap: onRemove,
                customBorder: const CircleBorder(),
                child: const Padding(
                  padding: EdgeInsets.all(3),
                  child: Icon(Icons.close, size: 15, color: Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
