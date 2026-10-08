import 'package:flutter/material.dart';

import '../../shared/theme/app_theme.dart';

class FeedVoteBar extends StatefulWidget {
  final int score;
  final String? voteType;
  final bool authenticated;
  final Future<void> Function(String voteType) onVote;
  final VoidCallback onRequireAuth;

  const FeedVoteBar({
    super.key,
    required this.score,
    required this.voteType,
    required this.authenticated,
    required this.onVote,
    required this.onRequireAuth,
  });

  @override
  State<FeedVoteBar> createState() => _FeedVoteBarState();
}

class _FeedVoteBarState extends State<FeedVoteBar> {
  bool _busy = false;

  Future<void> _vote(String type) async {
    if (_busy) return;
    if (!widget.authenticated) {
      widget.onRequireAuth();
      return;
    }
    setState(() => _busy = true);
    try {
      await widget.onVote(type);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        tooltip: 'Upvote',
        visualDensity: VisualDensity.compact,
        onPressed: _busy ? null : () => _vote('up'),
        icon: Icon(
          widget.voteType == 'up'
              ? Icons.keyboard_arrow_up_rounded
              : Icons.arrow_upward_rounded,
          size: 19,
          color: widget.voteType == 'up' ? AppColors.accentBlue : null,
        ),
      ),
      SizedBox(
        width: 34,
        child: Text(
          '${widget.score}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
      IconButton(
        tooltip: 'Downvote',
        visualDensity: VisualDensity.compact,
        onPressed: _busy ? null : () => _vote('down'),
        icon: Icon(
          widget.voteType == 'down'
              ? Icons.keyboard_arrow_down_rounded
              : Icons.arrow_downward_rounded,
          size: 19,
          color: widget.voteType == 'down' ? AppColors.accentBlue : null,
        ),
      ),
    ],
  );
}
