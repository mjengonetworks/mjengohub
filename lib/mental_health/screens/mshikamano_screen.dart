// lib/mental_health/screens/mshikamano_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/mental_health_controller.dart';
import '../models/mental_health_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Design tokens — mirrors Videos / Discover screens exactly
// ─────────────────────────────────────────────────────────────────────────────
const _kDark    = Color(0xFF111827);
const _kSubtext = Color(0xFF9CA3AF);
const _kBg      = Color(0xFFF3F4F6);
const _kDivider = Color(0xFFF3F4F6);
const _kTeal    = Color(0xFF0D9488); // Mshikamano brand accent only
const _kBlue    = Color(0xFF2563EB); // app-wide blue — button & checkbox

// ═════════════════════════════════════════════════════════════════════════════
//  ROOT SCREEN
// ═════════════════════════════════════════════════════════════════════════════

class MshikamanoScreen extends StatelessWidget {
  const MshikamanoScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final ctrl   = Get.put(MentalHealthController());
    final topPad = MediaQuery.of(context).padding.top;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: topPad + 12),

            // ── Header ──────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back button + title on same row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () => Get.back(),
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: _kBg,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new_rounded,
                              color: _kDark, size: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Mshikamano',
                            style: GoogleFonts.montserrat(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: _kDark,
                            ),
                          ),
                          Text(
                            'A safe space for construction workers.',
                            style: GoogleFonts.montserrat(
                              fontSize: 11,
                              color: _kSubtext,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),

            // ── Crisis banner ────────────────────────────────────────────────
            const _CrisisBanner(),

            // ── Body ─────────────────────────────────────────────────────────
            Expanded(
              child: Obx(() {
                if (ctrl.isLoading.value) {
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(_kDark),
                    ),
                  );
                }
                return ListView(
                  padding: const EdgeInsets.only(bottom: 40),
                  children: [
                    if (ctrl.videos.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      _VideosSection(ctrl: ctrl),
                    ],
                    const SizedBox(height: 20),
                    _MessageWall(ctrl: ctrl),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20),
                      child: Divider(height: 1, color: _kDivider),
                    ),
                    const SizedBox(height: 20),
                    _ShareFormCard(ctrl: ctrl),
                  ],
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  CRISIS BANNER
// ═════════════════════════════════════════════════════════════════════════════

class _CrisisBanner extends StatelessWidget {
  const _CrisisBanner();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final uri = Uri.parse('tel:+254722178177');
        if (await canLaunchUrl(uri)) await launchUrl(uri);
      },
      child: Container(
        margin: const EdgeInsets.fromLTRB(20, 0, 20, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF1F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFCDD2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE4E6),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.phone_rounded,
                      color: Color(0xFFDC2626), size: 16),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Crisis Support',
                      style: GoogleFonts.montserrat(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFDC2626),
                      ),
                    ),
                    Text(
                      'Befrienders Kenya · +254 722 178 177',
                      style: GoogleFonts.montserrat(
                        fontSize: 11.5,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  VIDEOS SECTION
// ═════════════════════════════════════════════════════════════════════════════

class _VideosSection extends StatelessWidget {
  final MentalHealthController ctrl;
  const _VideosSection({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Words of Encouragement',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Short messages from your industry colleagues.',
            style: GoogleFonts.montserrat(fontSize: 13, color: _kSubtext),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: ctrl.videos.length,
            itemBuilder: (_, i) => _VideoCard(video: ctrl.videos[i]),
          ),
        ),
        const SizedBox(height: 20),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 20),
          child: Divider(height: 1, color: _kDivider),
        ),
      ],
    );
  }
}

class _VideoCard extends StatelessWidget {
  final MentalHealthVideo video;
  const _VideoCard({required this.video});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final url = video.youtubeUrl;
        if (url != null) {
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        }
      },
      child: Container(
        width: 148,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: _kDivider),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(12)),
              child: SizedBox(
                height: 90,
                width: double.infinity,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    video.thumbnailUrl != null
                        ? Image.network(video.thumbnailUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                        : _placeholder(),
                    Center(
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.45),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Text(
                  video.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.montserrat(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: _kDark,
                    height: 1.3,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: _kBg,
        child: const Center(
          child: Icon(Icons.videocam_rounded,
              color: Color(0xFFCCCCDD), size: 28),
        ),
      );
}

// ═════════════════════════════════════════════════════════════════════════════
//  MESSAGE WALL
// ═════════════════════════════════════════════════════════════════════════════

class _MessageWall extends StatelessWidget {
  final MentalHealthController ctrl;
  const _MessageWall({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'The Message Wall',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text(
            'Real words from real people in the industry.',
            style: GoogleFonts.montserrat(fontSize: 13, color: _kSubtext),
          ),
        ),
        const SizedBox(height: 16),
        if (ctrl.posts.isEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
            child: Text(
              'No messages yet. Be the first to share!',
              style: GoogleFonts.montserrat(
                  fontSize: 13, color: _kSubtext),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: ctrl.posts.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 20,
              endIndent: 20,
              color: _kDivider,
            ),
            itemBuilder: (_, i) => _MessageTile(post: ctrl.posts[i]),
          ),
        const SizedBox(height: 8),
      ],
    );
  }
}

class _MessageTile extends StatelessWidget {
  final MentalHealthPost post;
  const _MessageTile({required this.post});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (post.isFeatured) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: _kTeal.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Featured',
                style: GoogleFonts.montserrat(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: _kTeal,
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            '"${post.message}"',
            style: GoogleFonts.montserrat(
              fontSize: 13.5,
              color: _kDark,
              fontStyle: FontStyle.italic,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                '— ${post.authorName}',
                style: GoogleFonts.montserrat(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kSubtext,
                ),
              ),
              const Spacer(),
              Text(
                post.monthYear,
                style: GoogleFonts.montserrat(
                    fontSize: 11, color: _kSubtext),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
//  SHARE FORM CARD
// ═════════════════════════════════════════════════════════════════════════════

class _ShareFormCard extends StatelessWidget {
  final MentalHealthController ctrl;
  const _ShareFormCard({required this.ctrl});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Share Your Story',
            style: GoogleFonts.montserrat(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: _kDark,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Your words could be exactly what someone else needs to hear.',
            style: GoogleFonts.montserrat(fontSize: 13, color: _kSubtext),
          ),
          const SizedBox(height: 16),
          _ShareForm(ctrl: ctrl),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  SHARE FORM (stateful)
// ─────────────────────────────────────────────────────────────────────────────

class _ShareForm extends StatefulWidget {
  final MentalHealthController ctrl;
  const _ShareForm({required this.ctrl});

  @override
  State<_ShareForm> createState() => _ShareFormState();
}

class _ShareFormState extends State<_ShareForm> {
  final _messageCtrl = TextEditingController();
  final _nameCtrl    = TextEditingController();
  bool _isAnonymous  = true;

  @override
  void dispose() {
    _messageCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      // ── Success state ──────────────────────────────────────────────────
      if (widget.ctrl.submitted.value) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: _kTeal.withOpacity(0.07),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kTeal.withOpacity(0.2)),
          ),
          child: Column(
            children: [
              const Icon(Icons.check_circle_outline_rounded,
                  color: _kTeal, size: 44),
              const SizedBox(height: 12),
              Text(
                'Thank you for sharing!',
                style: GoogleFonts.montserrat(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Your message will appear on the wall after admin review.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserrat(
                    fontSize: 13, color: _kSubtext),
              ),
            ],
          ),
        );
      }

      // ── Form ───────────────────────────────────────────────────────────
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message field
          _Field(
            controller: _messageCtrl,
            hint: 'What would you like to say to your fellow construction professionals? (min 10 chars)',
            maxLines: 5,
            maxLength: 2000,
          ),
          const SizedBox(height: 10),

          // Name field
          _Field(
            controller: _nameCtrl,
            hint: 'Your name (or leave blank for Anonymous)',
            enabled: !_isAnonymous,
          ),
          const SizedBox(height: 10),

          // Anonymous toggle
          GestureDetector(
            onTap: () => setState(() => _isAnonymous = !_isAnonymous),
            behavior: HitTestBehavior.opaque,
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 150),
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: _isAnonymous ? _kBlue : Colors.white,
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: _isAnonymous ? _kBlue : const Color(0xFFD1D5DB),
                    ),
                  ),
                  child: _isAnonymous
                      ? const Icon(Icons.check_rounded,
                          size: 13, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 8),
                Text(
                  'Post Anonymously',
                  style: GoogleFonts.montserrat(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _kDark,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Submit button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: widget.ctrl.submitting.value ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: widget.ctrl.submitting.value
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(
                      'Submit Message',
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All messages are reviewed before appearing on the wall.',
            style: GoogleFonts.montserrat(
                fontSize: 11, color: _kSubtext),
          ),
        ],
      );
    });
  }

  void _submit() {
    widget.ctrl.submitPost(
      message: _messageCtrl.text,
      authorName: _nameCtrl.text.trim().isEmpty
          ? 'Anonymous'
          : _nameCtrl.text.trim(),
      isAnonymous: _isAnonymous,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Reusable input field
// ─────────────────────────────────────────────────────────────────────────────

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final int? maxLength;
  final bool enabled;

  const _Field({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      maxLength: maxLength,
      enabled: enabled,
      style: GoogleFonts.montserrat(fontSize: 13.5, color: _kDark),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.montserrat(fontSize: 12.5, color: _kSubtext),
        filled: true,
        fillColor: enabled ? _kBg : const Color(0xFFF9FAFB),
        counterStyle:
            GoogleFonts.montserrat(fontSize: 10.5, color: _kSubtext),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _kTeal, width: 1.5),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
