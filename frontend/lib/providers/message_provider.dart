import 'package:flutter/material.dart';
import 'dart:convert' show base64Decode, jsonDecode;
import 'package:socket_io_client/socket_io_client.dart' as io;
import '../models/message.dart';
import '../services/message_service.dart';
import '../services/socket_service.dart';

class MessageProvider extends ChangeNotifier {
  io.Socket? _socket;
  String? _myUserId; // set when socket connects, used to key private chats correctly

  List<ChatGroup> _groups = [];
  List<Conversation> _conversations = [];
  List<ChatMessage> _starredMessages = [];

  // Active chat messages keyed by groupId or partnerId
  final Map<String, List<ChatMessage>> _chatMessages = {};

  final bool _loading = false;
  String? _error;
  
  // 🔥 REQUEST LOCK: Prevent duplicate API calls
  bool _isFetchingPrivate = false;
  
  // 🔥 MARK-AS-READ: Only mark when new messages arrive
  final Set<String> _hasMarkedAsRead = {};

  List<ChatGroup> get groups => _groups;
  List<Conversation> get conversations => _conversations;
  List<ChatMessage> get starredMessages => _starredMessages;
  bool get loading => _loading;
  String? get error => _error;

  List<ChatMessage> messagesFor(String key) {
    // Always normalize admin keys to 'moodle-2'
    const adminAppId = 'moodle-2';
    String normalizedKey = (key == 'admin' || key == adminAppId) ? adminAppId : key;
    return _chatMessages[normalizedKey] ?? [];
  }

  // ─── Socket ───────────────────────────────────────────────────────────────

  /// Extract user ID from JWT token (without external package).
  /// JWT format: header.payload.signature
  /// payload contains: {"id": "moodle-2", "iat": ..., "exp": ..., ...}
  static String? _extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      // Decode base64url payload (add padding if needed)
      var payload = parts[1];
      switch (payload.length % 4) {
        case 2:
          payload += '==';
          break;
        case 3:
          payload += '=';
          break;
      }

      final normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
      final decoded = String.fromCharCodes(base64Decode(normalized));
      final Map<String, dynamic> json = jsonDecode(decoded);
      return json['id'] as String?;
    } catch (e) {
      debugPrint('[MessageProvider] Failed to extract user ID from JWT: $e');
      return null;
    }
  }

  void connectSocket(String token, {String? myUserId}) {
    // ✅ Debug: log what we received
    debugPrint('[MessageProvider] 📍 connectSocket called:');
    debugPrint('   - Received myUserId param: $myUserId');
    debugPrint('   - Token length: ${token.length}');
    debugPrint('   - SocketService.isConnected: ${SocketService.isConnected}');
    debugPrint('   - SocketService.isConnecting: ${SocketService.isConnecting}');
    
    // Use provided myUserId, or extract from JWT if not provided
    _myUserId = myUserId;
    
    // If no myUserId provided, try to extract from JWT
    if (_myUserId == null || _myUserId!.isEmpty) {
      debugPrint('[MessageProvider] 🔍 Extracting user ID from JWT token...');
      final extractedId = _extractUserIdFromToken(token);
      debugPrint('[MessageProvider] ✅ Extracted from JWT: $extractedId');
      _myUserId = extractedId;
    }
    
    if (_myUserId == null || _myUserId!.isEmpty) {
      debugPrint('[MessageProvider] ❌ CRITICAL: Could not determine user ID for Socket listener!');
      return;
    }
    
    debugPrint('[MessageProvider] ✅ Set myUserId for Socket: $_myUserId');

    // ✅ Get socket from SocketService
    final socket = SocketService.socket;
    if (socket == null) {
      debugPrint('[MessageProvider] ⚠️ Socket not initialized - will retry when ready');
      // Socket should be initialized by AuthProvider after login
      return;
    }

    _socket = socket;
    debugPrint('[MessageProvider] 🔗 Got socket instance from SocketService');

    // ✅ Register the 'new_message' listener
    // Remove any previous listener to avoid duplicates
    SocketService.off('new_message');
    
    // Capture myUserId for this listener (closure)
    final capturedMyUserId = _myUserId;
    
    debugPrint('[MessageProvider] 📡 Registering new_message listener...');
    SocketService.on('new_message', (data) {
      _handleNewMessage(data, capturedMyUserId);
    });

    debugPrint('[MessageProvider] ✅ Socket listener registered');
  }

  /// ✅ Handle new message event from Socket.IO
  void _handleNewMessage(dynamic data, String? myUserId) {
    if (myUserId == null || myUserId.isEmpty) {
      debugPrint('[MessageProvider] ⚠️ Cannot process message - myUserId is empty');
      return;
    }

    debugPrint('🔔 [Socket] new_message received (myUserId=$myUserId)');
    try {
      final msg = ChatMessage.fromJson(Map<String, dynamic>.from(data));
      
      if (msg.type == 'group') {
        // ✅ Group message handling
        final key = msg.groupId ?? '';
        if (key.isEmpty) {
          debugPrint('   ⚠️ Group message missing groupId');
          return;
        }
        
        _chatMessages[key] ??= [];
        if (!_chatMessages[key]!.any((m) => m.id == msg.id)) {
          _chatMessages[key]!.add(msg);
          debugPrint('   ✅ Added group message to _chatMessages[$key]');
          notifyListeners();
        }
      } else {
        // ✅ Private message handling
        final senderId = msg.senderId;
        final recipientId = msg.recipientId ?? '';
        const adminId = 'moodle-2';

        debugPrint('   📧 Private: senderId=$senderId, recipientId=$recipientId, myUserId=$myUserId');

        // Determine if I sent this or received it
        final isSentByMe = (senderId == myUserId);
        String partnerKey = isSentByMe ? recipientId : senderId;

        if (partnerKey.isEmpty) {
          debugPrint('   ⚠️ Cannot determine partner for message');
          return;
        }

        // ✅ Always store admin messages under 'moodle-2' only
        String storeKey = (partnerKey == 'admin' || partnerKey == adminId) ? adminId : partnerKey;
        if (storeKey.isEmpty) return;
        _chatMessages[storeKey] ??= [];
        if (!_chatMessages[storeKey]!.any((m) => m.id == msg.id)) {
          _chatMessages[storeKey]!.add(msg);
          debugPrint('   ✅ Stored in _chatMessages[$storeKey]');
        }

        // ✅ Update conversation list using the SAME normalized key
        final isFromMe = msg.senderId == myUserId;
        if (storeKey.isNotEmpty) {
          // Use storeKey (normalized) to match how messages are stored
          final idx = _conversations.indexWhere((c) => c.partnerId == storeKey);
          final existingUnread = idx >= 0 ? _conversations[idx].unread : 0;
          final updatedConv = Conversation(
            partnerId: idx >= 0 ? _conversations[idx].partnerId : storeKey,
            partnerName: idx >= 0 ? _conversations[idx].partnerName : storeKey,
            lastMessage: msg,
            unread: isFromMe ? 0 : existingUnread + 1,
          );
          if (idx >= 0) {
            _conversations[idx] = updatedConv;
          } else {
            _conversations.insert(0, updatedConv);
          }
          _conversations.sort((a, b) =>
              b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp));
        }

        notifyListeners();
      }
    } catch (e) {
      debugPrint('   ❌ Error processing message: $e');
    }
  }

  void joinGroupRoom(String groupId) {
    if (_socket != null) {
      debugPrint('[MessageProvider] 📍 Joining group: $groupId');
      _socket!.emit('join_group', groupId);
    }
  }

  void leaveGroupRoom(String groupId) {
    if (_socket != null) {
      debugPrint('[MessageProvider] 🚪 Leaving group: $groupId');
      _socket!.emit('leave_group', groupId);
    }
  }

  void disconnectSocket() {
    debugPrint('[MessageProvider] 🔌 Disconnecting socket listener...');
    SocketService.off('new_message');
    _socket = null;
  }

  /// ✅ Clear all cached data — call on logout so the next user starts fresh.
    void clearAll() {
      debugPrint('[MessageProvider] 🗑️ Clearing all message data...');
      _chatMessages.clear();
      _conversations = [];
      _starredMessages = [];
      _groups = [];
      _myUserId = null;
      _hasMarkedAsRead.clear();  // 🔥 Clear mark-as-read tracking
      disconnectSocket();
      notifyListeners();
    }

  // ─── Load data ────────────────────────────────────────────────────────────

  Future<void> loadGroups() async {
    try {
      _groups = await MessageService.getGroups();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadConversations() async {
    try {
      _conversations = await MessageService.getConversations();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadStarred() async {
    try {
      _starredMessages = await MessageService.getStarred();
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> loadGroupMessages(String groupId) async {
    try {
      final msgs = await MessageService.getGroupMessages(groupId);
      _chatMessages[groupId] = msgs;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();    } finally {
      // 🔥 RELEASE LOCK
      _isFetchingPrivate = false;    }
  }

  Future<void> loadPrivateMessages(String chatKey) async {
    // 🔥 REQUEST LOCK: Prevent duplicate concurrent requests
    if (_isFetchingPrivate) return;
    _isFetchingPrivate = true;

    try {
      final msgs = await MessageService.getPrivateMessages(chatKey);
      
      // 🔥 ONLY mark as read if there are NEW messages from server
      if (msgs.isNotEmpty && !_hasMarkedAsRead.contains(chatKey)) {
        _hasMarkedAsRead.add(chatKey);
        await MessageService.markConversationRead(chatKey).catchError((_) {});
      }
      
      // Normalize keys: 'admin' and 'moodle-2' are the same conversation
      const adminAppId = 'moodle-2';
      final altKey = (chatKey == 'admin' || chatKey == adminAppId)
          ? (chatKey == 'admin' ? adminAppId : 'admin')
          : null;
      
      // Get existing messages from BOTH possible keys (in case Socket stored under different key)
      final existing = _chatMessages[chatKey] ?? [];
      final altExisting = altKey != null ? (_chatMessages[altKey] ?? []) : [];
      final allExisting = <ChatMessage>[];
      
      // Combine both lists, avoiding duplicates by ID
      final seenIds = <String>{};
      for (final m in existing) {
        if (seenIds.add(m.id)) allExisting.add(m);
      }
      for (final m in altExisting) {
        if (seenIds.add(m.id)) allExisting.add(m);
      }
      
      debugPrint('[MessageProvider] loadPrivateMessages: Got ${msgs.length} from API');
      debugPrint('   - Existing messages under "$chatKey": ${existing.length}');
      if (altKey != null) {
        debugPrint('   - Existing messages under "$altKey": ${altExisting.length}');
      }
      debugPrint('   - Total existing: ${allExisting.length}');
      
      // ✅ FIX: Log API response details
      if (msgs.isNotEmpty) {
        final first = msgs.first;
        final last = msgs.last;
        debugPrint('   - API response range:');
        debugPrint('     From: ${first.senderId} → ${first.recipientId} at ${first.timestamp}');
        debugPrint('     To:   ${last.senderId} → ${last.recipientId} at ${last.timestamp}');
      }
      
      // Always trust the server response — it has the correct senderId from the local store.
      // Only keep optimistic messages (no server id yet) that aren't in the server response.
      final serverIds = msgs.map((m) => m.id).toSet();
      final optimistic = allExisting
          .where((m) => !serverIds.contains(m.id))
          .toList();
      final merged = [...msgs, ...optimistic];
      merged.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      debugPrint('   - Merged ${merged.length} messages (${msgs.length} from API + ${optimistic.length} optimistic)');
      
      // ✅ FIX: Log final merged result
      if (merged.isNotEmpty) {
        final first = merged.first;
        final last = merged.last;
        debugPrint('   - Final display range:');
        debugPrint('     From: ${first.senderId} → ${first.recipientId} at ${first.timestamp}');
        debugPrint('     To:   ${last.senderId} → ${last.recipientId} at ${last.timestamp}');
      }
      // Store under the primary key
      _chatMessages[chatKey] = merged;
      
      // If there's an alt key and we have messages stored there, clear it to avoid confusion
      if (altKey != null && _chatMessages.containsKey(altKey)) {
        _chatMessages.remove(altKey);
        debugPrint('   - Cleaned up alt key "$altKey"');
      }
      
      // Clear unread count for this conversation
      clearUnread(chatKey);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    } finally {
      // 🔥 RELEASE LOCK
      _isFetchingPrivate = false;
    }
  }

  // ─── Send ─────────────────────────────────────────────────────────────────

  Future<void> sendGroupMessage(String groupId, String content) async {
    try {
      final msg = await MessageService.sendGroupMessage(groupId, content);
      _chatMessages[groupId] ??= [];
      if (!_chatMessages[groupId]!.any((m) => m.id == msg.id)) {
        _chatMessages[groupId]!.add(msg);
        notifyListeners();
      }
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendPrivateMessage(String chatKey, String content) async {
    try {
      final msg = await MessageService.sendPrivateMessage(
        recipientId: chatKey,
        content: content,
      );
      _chatMessages[chatKey] ??= [];
      if (!_chatMessages[chatKey]!.any((m) => m.id == msg.id)) {
        _chatMessages[chatKey]!.add(msg);
      }
      updateConversationLastMessage(chatKey, msg);
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ─── Star ─────────────────────────────────────────────────────────────────

  Future<void> toggleStar(String messageId) async {
    try {
      await MessageService.toggleStar(messageId);
      await loadStarred();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─── Mark conversation as read ───────────────────────────────────────────

  void clearUnread(String partnerId) {
    _conversations = _conversations.map((c) {
      if (c.partnerId == partnerId) {
        return Conversation(
          partnerId: c.partnerId,
          partnerName: c.partnerName,
          lastMessage: c.lastMessage,
          unread: 0,
        );
      }
      return c;
    }).toList();
    notifyListeners();
  }

  // ─── Update last message in conversation list ─────────────────────────────

  void updateConversationLastMessage(String partnerId, ChatMessage msg) {
    final idx = _conversations.indexWhere((c) => c.partnerId == partnerId);
    final updated = Conversation(
      partnerId: partnerId,
      partnerName: idx >= 0 ? _conversations[idx].partnerName : partnerId,
      lastMessage: msg,
      unread: 0,
    );
    if (idx >= 0) {
      _conversations[idx] = updated;
    } else {
      _conversations.insert(0, updated);
    }
    // Keep sorted by latest message
    _conversations.sort((a, b) =>
        b.lastMessage.timestamp.compareTo(a.lastMessage.timestamp));
    notifyListeners();
  }

  Future<void> joinGroup(String groupId) async {
    try {
      await MessageService.joinGroup(groupId);
      joinGroupRoom(groupId);
      await loadGroups();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  // ─── Create group ─────────────────────────────────────────────────────────

  Future<ChatGroup?> createGroup({
    required String name,
    String? description,
    String? moodleCourseId,
  }) async {
    try {
      final group = await MessageService.createGroup(
        name: name,
        description: description,
        moodleCourseId: moodleCourseId,
      );
      _groups.insert(0, group);
      notifyListeners();
      return group;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  @override
  void dispose() {
    disconnectSocket();
    super.dispose();
  }
}
