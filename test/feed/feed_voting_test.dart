import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mjengo_hub_app/feed/models/feed_model.dart';
import 'package:mjengo_hub_app/feed/services/feed_vote_service.dart';
import 'package:mjengo_hub_app/feed/widgets/feed_vote_bar.dart';

void main() {
  test('parses authoritative score and selected vote state', () {
    final result = FeedVoteResult.fromResponse({
      'success': true,
      'data': {
        'vote_type': 'down',
        'upvotes': 4,
        'downvotes': 7,
        'score': -3,
        'action': 'switched',
      },
    });
    final engagement = FeedEngagement.fromJson({
      'upvote_count': 4,
      'downvote_count': 7,
      'score': -3,
      'vote_type': 'down',
    });

    expect(result.voteType, 'down');
    expect(result.score, -3);
    expect(result.action, 'switched');
    expect(engagement.netScore, -3);
    expect(engagement.voteType, 'down');
  });

  testWidgets(
    'vote bar prevents rapid duplicate submissions and supports guest sign-in',
    (tester) async {
      var submissions = 0;
      var signInRequests = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedVoteBar(
              score: 2,
              voteType: null,
              authenticated: true,
              onRequireAuth: () => signInRequests++,
              onVote: (_) async {
                submissions++;
                await Future<void>.delayed(const Duration(milliseconds: 50));
              },
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Upvote'));
      await tester.tap(find.byTooltip('Upvote'));
      await tester.pump(const Duration(milliseconds: 70));
      expect(submissions, 1);
      expect(find.text('2'), findsOneWidget);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FeedVoteBar(
              score: 0,
              voteType: null,
              authenticated: false,
              onRequireAuth: () => signInRequests++,
              onVote: (_) async {},
            ),
          ),
        ),
      );
      await tester.tap(find.byTooltip('Downvote'));
      expect(signInRequests, 1);
    },
  );
}
