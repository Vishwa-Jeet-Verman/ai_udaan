// Safety net: strip [SENDER:...] prefix if backend failed to decode it
final _senderPrefixRe = RegExp(r'^\[SENDER:[^\]]+:[^\]]*\] ');

String _cleanContent(String raw) {
  return raw.replaceFirst(_senderPrefixRe, '');
}

class ChatMessage {
  final String id;
  final String type; // 'group' | 'private' | 'starred'
  final String senderId;
  final String senderName;
  final String senderRole;
  final String content;
  final String? groupId;
  final String? recipientId;
  final DateTime timestamp;
  final List<String> readBy;

  ChatMessage({
    required this.id,
    required this.type,
    required this.senderId,
    required this.senderName,
    required this.senderRole,
    required this.content,
    this.groupId,
    this.recipientId,
    required this.timestamp,
    required this.readBy,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    // Handle both our local format and Moodle normalized format
    final rawTimestamp = json['timestamp'] as String?;
    final timecreated = json['timecreated'];
    DateTime ts;
    if (rawTimestamp != null) {
      ts = DateTime.tryParse(rawTimestamp) ?? DateTime.now();
    } else if (timecreated != null) {
      ts = DateTime.fromMillisecondsSinceEpoch(
          (int.tryParse(timecreated.toString()) ?? 0) * 1000);
    } else {
      ts = DateTime.now();
    }

    return ChatMessage(
      id: json['id']?.toString() ?? '',
      type: json['type'] ?? 'private',
      senderId: json['senderId'] ?? '',
      senderName: json['senderName'] ?? '',
      senderRole: json['senderRole'] ?? 'student',
      content: _cleanContent(json['content'] ?? ''),
      groupId: json['groupId'] as String?,
      recipientId: json['recipientId'] as String?,
      timestamp: ts,
      readBy: List<String>.from(json['readBy'] ?? []),
    );
  }
}

class ChatGroup {
  final String id;
  final String name;
  final String description;
  final String createdBy;
  final String createdByName;
  final List<String> members;
  final String? moodleCourseId;
  final DateTime createdAt;

  ChatGroup({
    required this.id,
    required this.name,
    required this.description,
    required this.createdBy,
    required this.createdByName,
    required this.members,
    this.moodleCourseId,
    required this.createdAt,
  });

  factory ChatGroup.fromJson(Map<String, dynamic> json) {
    return ChatGroup(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      createdBy: json['createdBy'] ?? '',
      createdByName: json['createdByName'] ?? '',
      members: List<String>.from(json['members'] ?? []),
      moodleCourseId: json['moodleCourseId'] as String?,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
    );
  }
}

class Conversation {
  final String partnerId;
  final String partnerName;
  final ChatMessage lastMessage;
  final int unread;

  Conversation({
    required this.partnerId,
    required this.partnerName,
    required this.lastMessage,
    required this.unread,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      partnerId: json['partnerId'] ?? '',
      partnerName: json['partnerName'] ?? '',
      lastMessage: ChatMessage.fromJson(json['lastMessage']),
      unread: json['unread'] ?? 0,
    );
  }
}
