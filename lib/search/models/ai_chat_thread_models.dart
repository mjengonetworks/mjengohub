// lib/search/models/ai_chat_thread_models.dart
//
// Models for the "My Chats" thread history feature on the Omnibar
// (`GET /api/ai-chat/threads`, `GET /api/ai-chat/threads/<id>`,
// `POST /api/ai/chat/followup`). **None of these routes are confirmed
// live** — direct checks against all three 404 (checked 2026-09-19, same
// day as this feature). Wired end-to-end anyway, same "ready the moment the
// backend adds it, degrade to a clear empty state until then" pattern
// CLAUDE.md documents for `auth/google`/`auth/forgot-password` and
// `ai-search` (see ai_search_models.dart). Shape below matches the
// request's spec exactly since there's no live response to verify against.
class AiChatThread {
  final String id;
  final String title;
  final DateTime? updatedAt;

  const AiChatThread({required this.id, required this.title, this.updatedAt});

  factory AiChatThread.fromJson(Map<String, dynamic> j) => AiChatThread(
    id: (j['thread_id'] ?? j['id'] ?? '').toString(),
    title: (j['title'] ?? j['summary'] ?? j['last_message'] ?? 'Chat')
        .toString(),
    updatedAt: DateTime.tryParse(
      (j['updated_at'] ?? j['last_updated'] ?? '').toString(),
    ),
  );
}

class AiChatMessage {
  final String role;
  final String content;

  const AiChatMessage({required this.role, required this.content});

  bool get isUser => role == 'user';

  factory AiChatMessage.fromJson(Map<String, dynamic> j) => AiChatMessage(
    role: (j['role'] ?? (j['is_user'] == true ? 'user' : 'assistant'))
        .toString(),
    content: (j['content'] ?? j['message'] ?? j['text'] ?? '').toString(),
  );
}

class AiChatThreadDetail {
  final String id;
  final List<AiChatMessage> messages;

  const AiChatThreadDetail({required this.id, this.messages = const []});

  factory AiChatThreadDetail.fromJson(String id, Map<String, dynamic> j) {
    final raw = j['messages'];
    final messages = raw is List
        ? raw
              .whereType<Map<String, dynamic>>()
              .map(AiChatMessage.fromJson)
              .toList()
        : const <AiChatMessage>[];
    return AiChatThreadDetail(id: id, messages: messages);
  }
}
