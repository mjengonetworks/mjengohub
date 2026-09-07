// lib/shared/widgets/social_share_modal.dart
//
// Was a hand-rolled bottom sheet with per-network deep links (WhatsApp/X/
// LinkedIn intent URLs + a manual "Copy Link" button) that never actually
// called share_plus despite importing it. Replaced with the platform's
// native share sheet (ACTION_SEND on Android, UIActivityViewController on
// iOS) via Share.share — this already gives every installed app (WhatsApp,
// X, LinkedIn, Facebook, ...) plus the OS's own "Copy Link" action, so there
// is nothing left for a custom sheet to add. Kept the class/method name
// (`SocialShareModal.show`) so call sites didn't need to change shape, only
// gained an optional `summary` param.
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

class SocialShareModal {
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String url,
    String? summary,
  }) async {
    final text = [
      title,
      if (summary != null && summary.trim().isNotEmpty) summary.trim(),
      url,
    ].join('\n\n');
    await Share.share(text, subject: title);
  }
}
