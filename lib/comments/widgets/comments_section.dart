// lib/comments/widgets/comments_section.dart
//
// Reusable, Reddit-style threaded discussion widget: nested replies get a
// vertical guideline per depth level, sign-in is enforced before posting a
// comment or reply (auth prompt dialog if logged out), and each author's
// name carries their live reviewer-level badge.
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/badges.dart';
import '../models/comment_model.dart';
import '../services/comments_service.dart';

class CommentsSection extends StatefulWidget {
  final CommentResource resource;
  final int resourceId;
  final String title;

  const CommentsSection({
    super.key,
    required this.resource,
    required this.resourceId,
    this.title = 'Discussion',
  });

  @override
  State<CommentsSection> createState() => _CommentsSectionState();
}

class _CommentsSectionState extends State<CommentsSection> {
  final _service = CommentsService();
  final _inputCtrl = TextEditingController();
  List<ThreadedComment> _comments = [];
  bool _loading = true;
  bool _posting = false;
  int? _replyingToId;
  String? _replyingToName;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final result = await _service.getComments(widget.resource, widget.resourceId);
    if (!mounted) return;
    setState(() {
      _comments = result;
      _loading = false;
    });
  }

  int get _totalCount {
    int count(List<ThreadedComment> list) =>
        list.length + list.fold<int>(0, (sum, c) => sum + count(c.replies));
    return count(_comments);
  }

  MjengoAuthController? get _auth {
    try {
      return Get.find<MjengoAuthController>();
    } catch (_) {
      return null;
    }
  }

  bool get _isSignedIn => _auth?.isAuthenticated ?? false;

  void _requireAuthThen(VoidCallback action) {
    if (_isSignedIn) {
      action();
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.sharpLg)),
        title: Text('Sign in required', style: GoogleFonts.montserrat(fontWeight: FontWeight.w500)),
        content: Text(
          'Please sign in to your Mjengo Hub account to join the discussion.',
          style: GoogleFonts.montserrat(fontSize: 13.5, color: AppColors.textSubtle),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancel', style: GoogleFonts.montserrat(color: AppColors.textSubtle)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Get.toNamed(AppRoutes.login);
            },
            child: Text('Sign In', style: GoogleFonts.montserrat(color: Colors.white, fontWeight: FontWeight.w500)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final text = _inputCtrl.text.trim();
    if (text.isEmpty) return;
    final user = _auth?.currentUser;
    setState(() => _posting = true);
    final created = await _service.postComment(
      widget.resource,
      widget.resourceId,
      content: text,
      name: user?.fullName ?? user?.firstName ?? 'You',
      email: user?.email,
      parentId: _replyingToId,
    );
    if (!mounted) return;
    setState(() => _posting = false);
    if (created != null) {
      _inputCtrl.clear();
      setState(() {
        _replyingToId = null;
        _replyingToName = null;
      });
      _load();
    } else {
      Get.snackbar('Couldn\'t post', 'Please try again in a moment.',
          snackPosition: SnackPosition.BOTTOM, margin: const EdgeInsets.all(16));
    }
  }

  void _startReply(ThreadedComment c) {
    _requireAuthThen(() {
      setState(() {
        _replyingToId = c.id;
        _replyingToName = c.authorName;
      });
      FocusScope.of(context).requestFocus(FocusNode());
    });
  }

  Future<void> _vote(ThreadedComment c, bool up) async {
    _requireAuthThen(() async {
      final ok = await _service.vote(c.id, up: up);
      if (ok) _load();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.title,
              style: GoogleFonts.montserrat(fontSize: 15, fontWeight: FontWeight.w500, color: AppColors.textDark),
            ),
            const SizedBox(width: 6),
            Text('($_totalCount)', style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle)),
          ],
        ),
        const SizedBox(height: 12),
        _buildInput(),
        const SizedBox(height: 16),
        if (_loading)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accentBlue)),
          )
        else if (_comments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Text(
              'No comments yet. Be the first to share your thoughts.',
              style: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle),
            ),
          )
        else
          Column(
            children: _comments.map((c) => _CommentTile(
                  comment: c,
                  depth: 0,
                  onReply: _startReply,
                  onVote: _vote,
                )).toList(),
          ),
      ],
    );
  }

  Widget _buildInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_replyingToId != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(
              children: [
                Text('Replying to $_replyingToName',
                    style: GoogleFonts.montserrat(fontSize: 11.5, color: AppColors.accentBlue, fontWeight: FontWeight.w600)),
                const SizedBox(width: 6),
                GestureDetector(
                  onTap: () => setState(() {
                    _replyingToId = null;
                    _replyingToName = null;
                  }),
                  child: const Icon(Icons.close_rounded, size: 14, color: AppColors.textSubtle),
                ),
              ],
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: TextField(
                  controller: _inputCtrl,
                  minLines: 1,
                  maxLines: 4,
                  onTap: () {
                    if (!_isSignedIn) {
                      FocusScope.of(context).unfocus();
                      _requireAuthThen(() {});
                    }
                  },
                  style: GoogleFonts.montserrat(fontSize: 13),
                  decoration: InputDecoration(
                    hintText: _isSignedIn ? 'Add to the discussion...' : 'Sign in to comment...',
                    hintStyle: GoogleFonts.montserrat(fontSize: 13, color: AppColors.textSubtle),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _posting ? null : () => _requireAuthThen(_submit),
              child: Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(color: AppColors.accentBlue, shape: BoxShape.circle),
                child: _posting
                    ? const Padding(
                        padding: EdgeInsets.all(10),
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.arrow_upward_rounded, color: Colors.white, size: 20),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Reddit-style nested comment tile ─────────────────────────────────────────

class _CommentTile extends StatelessWidget {
  final ThreadedComment comment;
  final int depth;
  final void Function(ThreadedComment) onReply;
  final void Function(ThreadedComment, bool up) onVote;

  const _CommentTile({
    required this.comment,
    required this.depth,
    required this.onReply,
    required this.onVote,
  });

  static const List<Color> _guidelineColors = [
    Color(0xFFDCE6FA),
    Color(0xFFBFD3F5),
    Color(0xFFA3C0F0),
  ];

  @override
  Widget build(BuildContext context) {
    final guidelineColor = _guidelineColors[depth % _guidelineColors.length];

    return Padding(
      padding: EdgeInsets.only(left: depth == 0 ? 0 : 14, top: depth == 0 ? 14 : 10),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (depth > 0)
              Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(width: 2, color: guidelineColor),
              ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: depth == 0 ? 15 : 12,
                        backgroundColor: AppColors.accentBlue.withValues(alpha: 0.12),
                        backgroundImage: comment.authorPhotoUrl != null && comment.authorPhotoUrl!.isNotEmpty
                            ? NetworkImage(comment.authorPhotoUrl!)
                            : null,
                        child: comment.authorPhotoUrl == null || comment.authorPhotoUrl!.isEmpty
                            ? Text(
                                comment.authorName.isNotEmpty ? comment.authorName[0].toUpperCase() : '?',
                                style: GoogleFonts.montserrat(
                                    fontSize: depth == 0 ? 12 : 10,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.accentBlue),
                              )
                            : null,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 6,
                              runSpacing: 2,
                              children: [
                                Text(comment.authorName,
                                    style: GoogleFonts.montserrat(fontSize: 12.5, fontWeight: FontWeight.w500, color: AppColors.textDark)),
                                ReviewerLevelBadge(points: comment.authorPoints, small: true),
                              ],
                            ),
                            const SizedBox(height: 3),
                            Text(comment.content,
                                style: GoogleFonts.montserrat(fontSize: 12.5, color: AppColors.textDark, height: 1.4)),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                _VoteButton(icon: Icons.arrow_upward_rounded, onTap: () => onVote(comment, true)),
                                const SizedBox(width: 4),
                                Text('${comment.netScore}',
                                    style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.textSubtle)),
                                const SizedBox(width: 4),
                                _VoteButton(icon: Icons.arrow_downward_rounded, onTap: () => onVote(comment, false)),
                                const SizedBox(width: 12),
                                GestureDetector(
                                  onTap: () => onReply(comment),
                                  child: Text('Reply',
                                      style: GoogleFonts.montserrat(fontSize: 11.5, fontWeight: FontWeight.w500, color: AppColors.accentBlue)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  for (final reply in comment.replies)
                    _CommentTile(comment: reply, depth: depth + 1, onReply: onReply, onVote: onVote),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _VoteButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Icon(icon, size: 15, color: AppColors.textSubtle),
    );
  }
}
