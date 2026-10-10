# Mjengo Hub Flutter task tracker

Status rules:

- **Pending**: the relevant work has not been pushed.
- **Testing**: the relevant work has been pushed and is awaiting approval.
- **Completed**: explicitly approved by the user.

## Pending

1. Generate Android App Bundle (AAB)
   - No release bundle has been approved or pushed for this task.

2. Inspect and verify generated bundle
   - Pending a generated AAB.

3. Publish Play Store update
   - No Play Store publication has been approved or performed.

4. Production QA and verification
   - Pending release publication and explicit QA approval.

5. Purge Cloudflare cache
   - No cache purge has been approved or performed.

7. Push notifications
   - No verified Flutter implementation has been pushed for this task.

8. In-app purchases and subscriptions
   - No verified implementation has been pushed.

11. Image watermarks
   - No verified implementation has been pushed.

12. Article text-to-speech
   - No verified implementation has been pushed.

14. Opera-style swipe animations
   - No verified implementation has been pushed.

27.1. Feed reporting and moderation
   - Backend prerequisite 27.1A was pushed in website commits `d6803a8` and `56203e6` and is Testing. Flutter reporting integration is implemented locally; task remains Pending until its push succeeds. Production deployment and owner approval remain unverified.

## Testing

6. Minimalist UI restyling
   - Related UI and navigation changes exist in pushed Git history; awaiting explicit approval.

9. Contextual AI chatbot
   - Existing AI/chat work exists in pushed Git history; awaiting explicit approval.

10. Native Android sharing
   - Native sharing work exists in pushed history; awaiting explicit approval.

13. AI summaries and social media captions
   - Article Quick AI Summary and its verified canonical URL support were pushed in commits `4c992de` and `ab703e7`; awaiting approval.

16. End-of-content recommendations
   - Recommendation work exists in pushed Git history; awaiting explicit approval.

15. Project detail view parity with mobile website
   - Project detail parity work was pushed in commit `82ca2b0`; awaiting approval.

17. Media & Feed foundation
   - Native Media & Feed foundation was pushed in commit `793b3e0`; awaiting approval.

17.1. Native Feed API and timeline
   - Backend Feed API was pushed in `b743c32` and the Flutter native timeline was pushed in `13f6e6b`; awaiting approval.
   - Live verification on 2026-10-07 returned HTTP 200 from `https://mjengohub.co.ke/api/v1/feed?page=1&per_page=15`, with real editorial records, normalized author/source/media data, safe HTTPS canonical URLs, and working pagination. The running production commit could not be attributed to `b743c32`; repository deployment evidence and production release access remain unavailable.

20. Native Feed composer and publishing
   - Authenticated text publishing was pushed in backend commit `18794bb` and Flutter commit `a068435`; awaiting approval. Media upload remains deferred pending a mobile-compatible upload contract.

20.1. Native Feed media attachments
   - Secure multipart image attachments were pushed in backend commit `7743ffa` and Flutter commit `faf9a9d`; awaiting approval. PNG/JPEG/GIF/WebP images are supported, up to four attachments and 8 MB per image. Video remains deferred because the mobile contract does not yet have equivalent content-level validation.

23. Native Feed discussions, comments and replies
   - Feed discussion API was pushed in backend commit `8b7eae1` and native Flutter discussion UI/API integration was pushed in commit `21477ec`; awaiting approval. Nested FeedPost comments/replies, pagination, authenticated text submission, moderation feedback and sign-in return routing are supported. Voting and reporting use separate follow-up contracts; see tasks 21 and 27.1.

21. Reddit-style Feed voting
   - Mobile Feed voting API was pushed in backend commit `a2c39c5` and native Flutter voting controls/state were pushed in commit `c0aa0d1`; awaiting approval. Upvote, downvote, toggle removal, direction switching, authoritative scores and selected-user vote state are supported for Feed posts and nested replies.

18. Incident detail view parity with mobile website
   - Incident detail parity work was pushed in commit `3258124`; awaiting approval.

## Completed

None. No task has been explicitly approved as completed.
