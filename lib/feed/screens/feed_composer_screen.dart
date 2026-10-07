import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/feed_controller.dart';
import '../../shared/theme/app_theme.dart';

class FeedComposerScreen extends StatefulWidget {
  final FeedController controller;

  const FeedComposerScreen({super.key, required this.controller});

  @override
  State<FeedComposerScreen> createState() => _FeedComposerScreenState();
}

class _FeedComposerScreenState extends State<FeedComposerScreen> {
  final _textController = TextEditingController();
  final _focusNode = FocusNode();
  String? _error;
  bool _submitting = false;
  bool _submittedForModeration = false;

  @override
  void initState() {
    super.initState();
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
      final result = await widget.controller.publishPost(content);
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
              'Text posts only. Media attachments will be supported after the mobile upload contract is available.',
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
