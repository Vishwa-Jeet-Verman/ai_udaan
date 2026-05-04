import '../config/api_config.dart';
import '../models/message.dart';
import 'api_service.dart';

class MessageService {
  // ─── Groups ───────────────────────────────────────────────────────────────

  static Future<List<ChatGroup>> getGroups() async {
    final res = await ApiService.get(ApiConfig.messageGroups, auth: true);
    final list = res['data'] as List? ?? [];
    return list.map((e) => ChatGroup.fromJson(e)).toList();
  }

  static Future<ChatGroup> createGroup({
    required String name,
    String? description,
    String? moodleCourseId,
  }) async {
    final res = await ApiService.post(
      ApiConfig.messageGroups,
      body: {
        'name': name,
        'description': ?description,
        'moodleCourseId': ?moodleCourseId,
      },
      auth: true,
    );
    return ChatGroup.fromJson(res['data']);
  }

  static Future<void> joinGroup(String groupId) async {
    await ApiService.post(ApiConfig.messageGroupJoin(groupId), auth: true);
  }

  static Future<void> leaveGroup(String groupId) async {
    await ApiService.post(ApiConfig.messageGroupLeave(groupId), auth: true);
  }

  // ─── Group messages ───────────────────────────────────────────────────────

  static Future<List<ChatMessage>> getGroupMessages(String groupId) async {
    final res = await ApiService.get(ApiConfig.messageGroupMessages(groupId), auth: true);
    final list = res['data'] as List? ?? [];
    return list.map((e) => ChatMessage.fromJson(e)).toList();
  }

  static Future<ChatMessage> sendGroupMessage(String groupId, String content) async {
    final res = await ApiService.post(
      ApiConfig.messageGroupMessages(groupId),
      body: {'content': content},
      auth: true,
    );
    return ChatMessage.fromJson(res['data']);
  }

  // ─── Private messages ─────────────────────────────────────────────────────

  static Future<List<Conversation>> getConversations() async {
    final res = await ApiService.get(ApiConfig.messagePrivateConversations, auth: true);
    final list = res['data'] as List? ?? [];
    return list.map((e) => Conversation.fromJson(e)).toList();
  }

  static Future<List<ChatMessage>> getPrivateMessages(String partnerId) async {
    final sesskey = await ApiService.getSesskey();
    final url = sesskey != null 
      ? '${ApiConfig.messagePrivate(partnerId)}?sesskey=$sesskey'
      : ApiConfig.messagePrivate(partnerId);
    final res = await ApiService.get(url, auth: true);
    final list = res['data'] as List? ?? [];
    return list.map((e) => ChatMessage.fromJson(e)).toList();
  }

  static Future<ChatMessage> sendPrivateMessage({
    required String recipientId,
    required String content,
  }) async {
    final res = await ApiService.post(
      ApiConfig.messageSendPrivate,
      body: {'recipientId': recipientId, 'content': content},
      auth: true,
    );
    return ChatMessage.fromJson(res['data']);
  }

  // ─── Starred ──────────────────────────────────────────────────────────────

  static Future<List<ChatMessage>> getStarred() async {
    final res = await ApiService.get(ApiConfig.messageStarred, auth: true);
    final list = res['data'] as List? ?? [];
    return list.map((e) => ChatMessage.fromJson(e)).toList();
  }

  static Future<bool> toggleStar(String messageId) async {
    final res = await ApiService.post(
      ApiConfig.messageToggleStar(messageId),
      auth: true,
    );
    return res['starred'] as bool? ?? false;
  }

  // ─── Mark read ────────────────────────────────────────────────────────────

  static Future<void> markRead(String messageId) async {
    await ApiService.post(ApiConfig.messageMarkRead(messageId), auth: true);
  }

  static Future<void> markConversationRead(String partnerId) async {
    await ApiService.post(ApiConfig.messagePrivateMarkRead(partnerId), auth: true);
  }
}
