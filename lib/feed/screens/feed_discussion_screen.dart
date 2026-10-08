import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../auth/controllers/mjengo_auth_controller.dart';
import '../../news/widgets/net_image.dart';
import '../../point/routes/app_routes.dart';
import '../../shared/theme/app_theme.dart';
import '../controllers/feed_discussion_controller.dart';
import '../models/feed_discussion_model.dart';
import '../models/feed_model.dart';

class FeedDiscussionScreen extends StatefulWidget {
  final FeedItem post;
  final FeedDiscussionController? controller;

  const FeedDiscussionScreen({super.key, required this.post, this.controller});

  @override
  State<FeedDiscussionScreen> createState() => _FeedDiscussionScreenState();
}

class _FeedDiscussionScreenState extends State<FeedDiscussionScreen> {
  late final FeedDiscussionController _controller;
  final _composer = TextEditingController();
  int? _replyingTo;
  String? _replyingName;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller =
        widget.controller ?? FeedDiscussionController(widget.post.id ?? 0);
    if (widget.controller == null) Get.put(_controller);
  }

  @override
  void dispose() {
    _composer.dispose();
    if (widget.controller == null &&
        Get.isRegistered<FeedDiscussionController>()) {
      Get.delete<FeedDiscussionController>();
    }
    super.dispose();
  }

  bool get _signedIn {
    try {
      return Get.find<MjengoAuthController>().isAuthenticated;
    } catch (_) {
      return false;
    }
  }

  void _requireSignIn() {
    if (_signedIn) return;
    Get.toNamed(
      AppRoutes.login,
      arguments: {
        'returnTo': AppRoutes.feedDiscussion,
        'returnArguments': {'post': widget.post},
      },
    );
  }

  Future<void> _submit() async {
    if (!_signedIn) return _requireSignIn();
    final content = _composer.text.trim();
    if (content.isEmpty || _submitting) return;
    setState(() => _submitting = true);
    try {
      await _controller.submit(content, parentId: _replyingTo);
      _composer.clear();
      if (mounted) {
        setState(() {
          _replyingTo = null;
          _replyingName = null;
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: Get.back,
        ),
        title: const Text('Discussion'),
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (_controller.isLoading.value && _controller.comments.isEmpty) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              if (_controller.errorMessage.value != null &&
                  _controller.comments.isEmpty) {
                return _StateMessage(
                  title: 'Could not load discussion',
                  message: _controller.errorMessage.value!,
                  action: _controller.load,
                );
              }
              return RefreshIndicator(
                onRefresh: _controller.load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 18),
                  children: [
                    _RootCard(post: widget.post),
                    const SizedBox(height: 12),
                    if (_controller.comments.isEmpty)
                      const Padding(
                        padding: EdgeInsets.all(22),
                        child: Center(
                          child: Text('No comments yet. Start the discussion.'),
                        ),
                      ),
                    for (final comment in _controller.comments)
                      _CommentNode(
                        comment: comment,
                        depth: 0,
                        onReply: (value) => setState(() {
                          _replyingTo = value.id;
                          _replyingName = value.author.displayName;
                        }),
                      ),
                    if (_controller.hasNext.value)
                      TextButton(
                        onPressed: _controller.loadMore,
                        child: _controller.isLoadingMore.value
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : const Text('Load more comments'),
                      ),
                  ],
                ),
              );
            }),
          ),
          Obx(() {
            final message = _controller.pendingMessage.value;
            if (message == null) return const SizedBox.shrink();
            return Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 4),
              child: Text(
                message,
                style: TextStyle(
                  color: theme.colorScheme.primary,
                  fontSize: 11,
                ),
              ),
            );
          }),
          _Composer(
            controller: _composer,
            replyingName: _replyingName,
            signedIn: _signedIn,
            submitting: _submitting,
            onTap: _requireSignIn,
            onCancelReply: () => setState(() {
              _replyingTo = null;
              _replyingName = null;
            }),
            onSubmit: _submit,
          ),
        ],
      ),
    );
  }
}

class _RootCard extends StatelessWidget {
  final FeedItem post;
  const _RootCard({required this.post});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Theme.of(context).colorScheme.surface,
      border: Border.all(color: AppColors.divider),
      borderRadius: BorderRadius.circular(AppRadius.sharp),
    ),
    child: Text(
      post.text ?? 'Feed post',
      style: GoogleFonts.montserrat(fontSize: 13, height: 1.45),
    ),
  );
}

class _CommentNode extends StatefulWidget {
  final FeedComment comment;
  final int depth;
  final ValueChanged<FeedComment> onReply;
  const _CommentNode({
    required this.comment,
    required this.depth,
    required this.onReply,
  });

  @override
  State<_CommentNode> createState() => _CommentNodeState();
}

class _CommentNodeState extends State<_CommentNode> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final comment = widget.comment;
    final theme = Theme.of(context);
    final name = comment.author.displayName ?? 'Community member';
    final indent = (widget.depth * 14).clamp(0, 56).toDouble();
    return Padding(
      padding: EdgeInsets.only(left: indent, bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(AppRadius.sharp),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                NetImage(
                  url: comment.author.avatarUrl,
                  width: 28,
                  height: 28,
                  borderRadius: BorderRadius.circular(14),
                  errorBuilder: (_) => CircleAvatar(
                    radius: 14,
                    child: Text(name.substring(0, 1).toUpperCase()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    name,
                    style: GoogleFonts.montserrat(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  _time(comment.createdAt),
                  style: const TextStyle(fontSize: 10),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              comment.content,
              style: GoogleFonts.montserrat(fontSize: 12.5, height: 1.4),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: () => widget.onReply(comment),
                  child: const Text('Reply'),
                ),
                if (comment.replies.isNotEmpty)
                  TextButton(
                    onPressed: () => setState(() => _expanded = !_expanded),
                    child: Text(
                      _expanded
                          ? 'Hide replies'
                          : '${comment.replies.length} replies',
                    ),
                  ),
              ],
            ),
            if (_expanded)
              for (final reply in comment.replies)
                _CommentNode(
                  comment: reply,
                  depth: widget.depth + 1,
                  onReply: widget.onReply,
                ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final String? replyingName;
  final bool signedIn;
  final bool submitting;
  final VoidCallback onTap;
  final VoidCallback onCancelReply;
  final VoidCallback onSubmit;
  const _Composer({
    required this.controller,
    required this.replyingName,
    required this.signedIn,
    required this.submitting,
    required this.onTap,
    required this.onCancelReply,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              readOnly: !signedIn,
              onTap: onTap,
              minLines: 1,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: replyingName == null
                    ? 'Add a comment…'
                    : 'Reply to $replyingName…',
                prefixIcon: replyingName == null
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close, size: 17),
                        onPressed: onCancelReply,
                      ),
                border: const OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(width: 6),
          IconButton(
            onPressed: submitting ? null : onSubmit,
            icon: submitting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.send_rounded, color: AppColors.accentBlue),
          ),
        ],
      ),
    ),
  );
}

class _StateMessage extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback action;
  const _StateMessage({
    required this.title,
    required this.message,
    required this.action,
  });
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(message, textAlign: TextAlign.center),
          TextButton(onPressed: action, child: const Text('Retry')),
        ],
      ),
    ),
  );
}

String _time(DateTime? value) {
  if (value == null) return 'Time unavailable';
  final delta = DateTime.now().difference(value.toLocal());
  if (delta.inMinutes < 1) return 'Just now';
  if (delta.inHours < 1) return '${delta.inMinutes}m ago';
  if (delta.inDays < 1) return '${delta.inHours}h ago';
  return '${value.day}/${value.month}/${value.year}';
}
