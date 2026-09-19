// lib/search/services/ai_chat_thread_service.dart
//
// "My Chats" thread history + follow-up persistence for the Omnibar. Talks
// to `/api/ai-chat/threads`, `/api/ai-chat/threads/<id>` and
// `/api/ai/chat/followup` — note these sit outside the `/api/v1/` prefix
// every other feature uses (as specced), so this goes through raw `http`
// with a full URL rather than BaseService/MjengoService, the same way
// BaseService.uploadFile bypasses GetConnect's baseUrl for multipart. See
// the doc comment on ai_chat_thread_models.dart: none of these three routes
// are confirmed live yet.
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/ai_chat_thread_models.dart';

const String _apiRoot = 'https://mjengohub.co.ke/api';
const String _accessTokenKey = 'mjengo_access_token';

class AiChatThreadService {
  Future<Map<String, String>> _headers({bool withBody = false}) async {
    final headers = {'Accept': 'application/json'};
    if (withBody) headers['Content-Type'] = 'application/json; charset=utf-8';
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_accessTokenKey);
      if (token != null) headers['Authorization'] = 'Bearer $token';
    } catch (e) {
      print('❌ AiChatThreadService token read failed: $e');
    }
    return headers;
  }

  /// `GET /api/ai-chat/threads` — the user's past conversation sessions,
  /// ordered by last-updated (newest first). Empty list on any failure
  /// (network, non-200, parse, or the 404 this route currently returns).
  Future<List<AiChatThread>> fetchThreads() async {
    try {
      final res = await http
          .get(Uri.parse('$_apiRoot/ai-chat/threads'), headers: await _headers())
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        print('❌ fetchThreads failed: ${res.statusCode}');
        return const [];
      }
      final body = jsonDecode(res.body);
      final list = body is Map<String, dynamic> ? body['data'] : body;
      if (list is! List) return const [];
      final threads = list
          .whereType<Map<String, dynamic>>()
          .map(AiChatThread.fromJson)
          .toList();
      threads.sort((a, b) {
        final au = a.updatedAt;
        final bu = b.updatedAt;
        if (au == null || bu == null) return 0;
        return bu.compareTo(au);
      });
      return threads;
    } catch (e) {
      print('❌ fetchThreads error: $e');
      return const [];
    }
  }

  /// `GET /api/ai-chat/threads/<thread_id>` — full message history for one
  /// thread. Null on any failure so the caller can show an explicit error
  /// instead of a silently-empty conversation.
  Future<AiChatThreadDetail?> fetchThreadDetail(String threadId) async {
    try {
      final res = await http
          .get(
            Uri.parse('$_apiRoot/ai-chat/threads/$threadId'),
            headers: await _headers(),
          )
          .timeout(const Duration(seconds: 30));
      if (res.statusCode != 200) {
        print('❌ fetchThreadDetail($threadId) failed: ${res.statusCode}');
        return null;
      }
      final body = jsonDecode(res.body);
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is! Map<String, dynamic>) return null;
      return AiChatThreadDetail.fromJson(threadId, data);
    } catch (e) {
      print('❌ fetchThreadDetail($threadId) error: $e');
      return null;
    }
  }

  /// `POST /api/ai/chat/followup` — persists a follow-up turn against
  /// [threadId] so it survives across sessions. Returns the assistant's
  /// reply text (or null on failure) plus, when the backend starts a new
  /// thread for a null [threadId], the thread id it assigned.
  Future<AiChatFollowUpResult?> sendFollowUp({
    required String message,
    String? threadId,
  }) async {
    try {
      final res = await http
          .post(
            Uri.parse('$_apiRoot/ai/chat/followup'),
            headers: await _headers(withBody: true),
            body: jsonEncode({
              'message': message,
              if (threadId != null) 'thread_id': threadId,
            }),
          )
          .timeout(const Duration(seconds: 60));
      if (res.statusCode != 200 && res.statusCode != 201) {
        print('❌ sendFollowUp failed: ${res.statusCode}');
        return null;
      }
      final body = jsonDecode(res.body);
      final data = body is Map<String, dynamic> ? (body['data'] ?? body) : body;
      if (data is! Map<String, dynamic>) return null;
      return AiChatFollowUpResult(
        threadId: (data['thread_id'] ?? threadId ?? '').toString(),
        reply: (data['reply'] ?? data['message'] ?? data['content'] ?? '')
            .toString(),
      );
    } catch (e) {
      print('❌ sendFollowUp error: $e');
      return null;
    }
  }
}

class AiChatFollowUpResult {
  final String threadId;
  final String reply;

  const AiChatFollowUpResult({required this.threadId, required this.reply});
}
