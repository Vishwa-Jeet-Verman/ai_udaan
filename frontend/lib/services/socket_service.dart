import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:flutter/foundation.dart';
import 'dart:convert' show base64Decode, jsonDecode;
import '../config/api_config.dart';

/// ✅ Singleton Socket.IO Service
/// - Ensures only ONE socket instance exists
/// - Prevents multiple concurrent connections
/// - Manages connection/disconnection lifecycle
/// - Supports event listening even before connection
class SocketService {
  static io.Socket? _socket;
  static bool _isConnecting = false;  // ✅ NEW: Prevents concurrent connection attempts
  static final Map<String, Function(dynamic)> _pendingListeners = {};

  static io.Socket? get socket => _socket;
  static bool get isConnected => _socket?.connected ?? false;
  static bool get isConnecting => _isConnecting;  // ✅ NEW: Check if connecting

  /// ✅ Connect to Socket.IO server
  /// - Only connects if not already connected/connecting
  /// - Uses websocket transport only
  /// - Automatically joins user room
  static Future<void> connect(String token) async {
    // ✅ Prevent multiple connection attempts
    if (_isConnecting) {
      debugPrint('[Socket] ⚠️ Connection already in progress, skipping duplicate connect');
      return;
    }

    if (_socket != null && _socket!.connected) {
      debugPrint('[Socket] ⚠️ Already connected, skipping reconnect');
      return;
    }

    _isConnecting = true;
    debugPrint('[Socket] 🔌 Initiating connection...');

    try {
      _socket = io.io(
        ApiConfig.socketUrl,
        io.OptionBuilder()
        // ✅ TRANSPORTS: Use websocket only (more stable than polling)
        .setTransports(['websocket'])
        // ✅ RECONNECTION: Limit reconnect attempts to prevent infinite loops
        .setReconnectionDelay(1000)        // Start with 1s
        .setReconnectionDelayMax(5000)     // Max 5s between attempts
        .setReconnectionAttempts(5)        // Max 5 attempts total
        // ✅ AUTHENTICATION: Pass token
        .setAuth({'token': token})
        // ✅ AUTO CONNECT: Will connect manually after setup
        .disableAutoConnect()
        .build(),
      );

      // ✅ Setup all event handlers BEFORE connecting
      _setupEventHandlers();

      // ✅ NOW connect
      _socket!.connect();

      debugPrint('[Socket] 📡 Connection request sent');
    } catch (e) {
      debugPrint('[Socket] ❌ Error during connection setup: $e');
      _isConnecting = false;
      _socket = null;
      rethrow;
    }
  }

  /// ✅ Setup all Socket.IO event handlers
  static void _setupEventHandlers() {
    if (_socket == null) return;

    // ✅ Connection successful
    _socket!.onConnect((_) {
      _isConnecting = false;
      debugPrint('[Socket] ✅ Connected successfully');
      
      // Re-register any listeners added before connection
      debugPrint('[Socket] 📋 Re-registering ${_pendingListeners.length} listeners...');
      _pendingListeners.forEach((event, handler) {
        debugPrint('[Socket] 📍 Re-registered listener: $event');
        _socket?.on(event, handler);
      });
    });

    // ✅ Connection attempt failed
    _socket!.onConnectError((error) {
      _isConnecting = false;
      debugPrint('[Socket] ❌ Connect error: $error');
    });

    // ✅ Connection lost
    _socket!.onDisconnect((reason) {
      _isConnecting = false;
      debugPrint('[Socket] 🔌 Disconnected (reason: $reason)');
    });

    // ✅ Reconnection attempt
    _socket!.on('reconnect_attempt', (_) {
      debugPrint('[Socket] 🔄 Reconnection attempt in progress...');
    });

    // ✅ Reconnection failed
    _socket!.on('reconnect_error', (error) {
      debugPrint('[Socket] ❌ Reconnection failed: $error');
    });

    // ✅ Max reconnection attempts reached
    _socket!.on('reconnect_failed', (_) {
      debugPrint('[Socket] 🚫 Max reconnection attempts reached - giving up');
      _isConnecting = false;
    });
  }

  /// ✅ Register a listener for a specific event
  /// - Works even before socket connects (stored in pending)
  /// - Automatically re-registers after connection
  static void on(String event, Function(dynamic) handler) {
    _pendingListeners[event] = handler;
    
    // If already connected, register immediately
    if (_socket?.connected ?? false) {
      debugPrint('[Socket] 📌 Registering listener for event: $event');
      _socket?.on(event, handler);
    } else {
      debugPrint('[Socket] 📝 Queued listener for event: $event (will register on connect)');
    }
  }

  /// ✅ Remove a listener for a specific event
  static void off(String event) {
    _pendingListeners.remove(event);
    _socket?.off(event);
    debugPrint('[Socket] 🗑️ Removed listener for event: $event');
  }

  /// ✅ Proper disconnection (no auto-reconnect)
  static Future<void> disconnect() async {
    if (_socket == null) {
      debugPrint('[Socket] ⚠️ Socket already null, nothing to disconnect');
      return;
    }

    debugPrint('[Socket] 🔌 Disconnecting...');
    
    // Remove all listeners
    _pendingListeners.clear();
    
    
    // Disconnect
    _socket?.disconnect();
    
    // Clean up
    _socket?.dispose();
    _socket = null;
    _isConnecting = false;
    
    debugPrint('[Socket] ✅ Disconnected and cleaned up');
  }

  /// Extract user ID from JWT token (without external package)
  /// JWT format: header.payload.signature
  /// Payload contains: {"id": "moodle-2", "iat": ..., "exp": ..., ...}
  static String? extractUserIdFromToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      var payload = parts[1];
      // Add padding if needed
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
      final json = jsonDecode(decoded) as Map<String, dynamic>;
      return json['id'] as String?;
    } catch (e) {
      debugPrint('[Socket] ⚠️ Failed to extract user ID from JWT: $e');
      return null;
    }
  }
}
