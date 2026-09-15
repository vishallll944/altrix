import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../../core/config/env.dart';
import '../models/patient_models.dart';

/// Real-time chat service powered by Socket.io client.
/// Handles instant messaging (<20ms), doctor typing indicator, and presence.
class ChatSocketService {
  ChatSocketService({this.baseUrl});

  final String? baseUrl;
  IO.Socket? _socket;

  bool get isConnected => _socket?.connected ?? false;

  final _messageController = StreamController<MessageModel>.broadcast();
  final _typingStatusController = StreamController<bool>.broadcast();
  final _presenceController = StreamController<String>.broadcast();
  final _connectionStatusController = StreamController<bool>.broadcast();

  Stream<MessageModel> get onNewMessage => _messageController.stream;
  Stream<bool> get onTypingStatus => _typingStatusController.stream;
  Stream<String> get onPresenceChange => _presenceController.stream;
  Stream<bool> get onConnectionChange => _connectionStatusController.stream;

  // Optional direct callbacks
  void Function(MessageModel message)? onMessageReceived;
  void Function(bool isTyping)? onDoctorTypingChanged;
  void Function(String status)? onDoctorPresenceChanged;
  void Function(bool isConnected)? onConnectionChanged;

  String? _currentThreadId;
  String? _currentPatientId;
  String? _currentPatientName;
  String? _currentToken;

  /// Connects to the Socket.io server with real-time events.
  void connectSocket({
    required String patientId,
    required String patientName,
    required String threadId,
    String? serverUrl,
    String? token,
  }) {
    _currentThreadId = threadId;
    _currentPatientId = patientId;
    _currentPatientName = patientName;
    _currentToken = token;

    // Disconnect existing socket cleanly before reconnecting
    if (_socket != null) {
      _socket!.off('new_message');
      _socket!.off('typing_status');
      _socket!.off('presence_change');
      _socket?.disconnect();
      _socket?.dispose();
      _socket = null;
    }

    final domain = (serverUrl != null && serverUrl.isNotEmpty)
        ? serverUrl
        : (baseUrl != null && baseUrl!.isNotEmpty ? baseUrl! : Env.apiBaseUrl);

    // Use polling first (more reliable through proxies/firewalls),
    // then upgrade to WebSocket — this is the standard socket.io sequence.
    final optionsBuilder = IO.OptionBuilder()
        .setTransports(['polling', 'websocket'])
        .setPath('/api/socket/io')
        .enableAutoConnect()
        .enableReconnection()
        .setReconnectionAttempts(double.infinity.toInt()) // retry forever
        .setReconnectionDelay(2000)
        .setReconnectionDelayMax(10000);

    if (token != null && token.isNotEmpty) {
      optionsBuilder.setAuth({'token': token});
      optionsBuilder.setExtraHeaders({'Authorization': 'Bearer $token'});
      optionsBuilder.setQuery({'token': token});
    }

    final newSocket = IO.io(domain, optionsBuilder.build());
    _socket = newSocket;

    // 1. Connection success
    newSocket.onConnect((_) {
      debugPrint('[ChatSocket] ✅ Connected → $domain (thread: $threadId)');
      _connectionStatusController.add(true);
      onConnectionChanged?.call(true);

      // Register user identity on the server
      newSocket.emit('register_user', {
        'id': patientId,
        'name': patientName,
        'role': 'patient',
      });

      // Join the specific chat thread room
      newSocket.emit('join_thread', {
        'threadId': threadId,
        'user': {
          'id': patientId,
          'name': patientName,
          'role': 'patient',
        },
      });
    });

    // 2. Incoming real-time messages from clinician
    newSocket.on('new_message', (data) {
      debugPrint('[ChatSocket] 📨 new_message: $data');
      try {
        Map<String, dynamic>? messageMap;
        if (data is Map<String, dynamic>) {
          if (data['message'] is Map<String, dynamic>) {
            messageMap = data['message'] as Map<String, dynamic>;
          } else if (data['data'] is Map<String, dynamic>) {
            messageMap = data['data'] as Map<String, dynamic>;
          } else {
            messageMap = data;
          }
        } else if (data is Map) {
          messageMap = Map<String, dynamic>.from(data);
        }

        if (messageMap != null) {
          final message = MessageModel.fromJson(messageMap);
          _messageController.add(message);
          onMessageReceived?.call(message);
        }
      } catch (err) {
        debugPrint('[ChatSocket] Error parsing new_message: $err');
      }
    });

    // 3. Doctor typing indicator
    newSocket.on('typing_status', (data) {
      bool isDoctorTyping = false;
      if (data is Map) {
        isDoctorTyping = data['isTyping'] == true;
      } else if (data is bool) {
        isDoctorTyping = data;
      }
      _typingStatusController.add(isDoctorTyping);
      onDoctorTypingChanged?.call(isDoctorTyping);
    });

    // 4. Clinician presence (online/offline)
    newSocket.on('presence_change', (data) {
      String status = 'online';
      if (data is Map && data['status'] != null) {
        status = data['status'].toString();
      } else if (data is String) {
        status = data;
      }
      _presenceController.add(status);
      onDoctorPresenceChanged?.call(status);
    });

    // 5. Disconnected
    newSocket.onDisconnect((reason) {
      debugPrint('[ChatSocket] ⚡ Disconnected: $reason');
      _connectionStatusController.add(false);
      onConnectionChanged?.call(false);
    });

    // 6. Connection error — LOG ONLY, do NOT disconnect.
    //    Socket.io fires connect_error during the polling→websocket upgrade
    //    phase, which is completely normal. Disconnecting here would prevent
    //    the socket from ever establishing a stable connection.
    newSocket.onConnectError((err) {
      debugPrint('[ChatSocket] ⚠️ connect_error (will retry): $err');
      // Do NOT call disconnect() here — let socket.io handle reconnection.
    });

    newSocket.onError((err) {
      debugPrint('[ChatSocket] ⚠️ error: $err');
    });

    newSocket.onReconnect((_) {
      debugPrint('[ChatSocket] 🔄 Reconnected — re-joining thread $threadId');
      // Re-register and re-join after reconnect
      newSocket.emit('register_user', {
        'id': patientId,
        'name': patientName,
        'role': 'patient',
      });
      newSocket.emit('join_thread', {
        'threadId': threadId,
        'user': {
          'id': patientId,
          'name': patientName,
          'role': 'patient',
        },
      });
    });
  }

  /// Emit a message via socket immediately after REST send.
  /// This lets the server broadcast the message to clinicians in real-time
  /// while the REST API persists it in the database.
  void emitMessage({
    required String threadId,
    required String message,
    required String senderId,
    required String senderName,
    String tempId = '',
  }) {
    if (_socket == null || !isConnected) return;
    _socket!.emit('send_message', {
      'threadId': threadId,
      'message': message,
      'sender': {
        'id': senderId,
        'name': senderName,
        'role': 'patient',
      },
      if (tempId.isNotEmpty) 'tempId': tempId,
    });
  }

  // Typing indicators
  void sendTypingStart([String? threadId, String? patientId, String? patientName]) {
    final tid = threadId ?? _currentThreadId;
    final pid = patientId ?? _currentPatientId;
    final pname = patientName ?? _currentPatientName;
    if (tid == null || pid == null || _socket == null || !isConnected) return;
    _socket!.emit('typing_start', {
      'threadId': tid,
      'user': {'id': pid, 'name': pname ?? 'Patient', 'role': 'patient'},
    });
  }

  void sendTypingStop([String? threadId, String? patientId, String? patientName]) {
    final tid = threadId ?? _currentThreadId;
    final pid = patientId ?? _currentPatientId;
    final pname = patientName ?? _currentPatientName;
    if (tid == null || pid == null || _socket == null || !isConnected) return;
    _socket!.emit('typing_stop', {
      'threadId': tid,
      'user': {'id': pid, 'name': pname ?? 'Patient', 'role': 'patient'},
    });
  }

  /// Call this when the app comes back to foreground to ensure the socket
  /// is still alive, and reconnect if needed.
  void reconnectIfNeeded() {
    if (_socket != null && !isConnected) {
      debugPrint('[ChatSocket] 🔄 App resumed — reconnecting socket');
      _socket!.connect();
    }
  }

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    if (!_connectionStatusController.isClosed) {
      _connectionStatusController.add(false);
    }
    onConnectionChanged?.call(false);
  }

  void dispose() {
    disconnect();
    _messageController.close();
    _typingStatusController.close();
    _presenceController.close();
    _connectionStatusController.close();
  }
}
