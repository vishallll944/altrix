import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

import '../../../../core/config/env.dart';
import '../models/patient_models.dart';

/// Real-time chat service powered by Socket.io client.
/// Handles instant messaging (<20ms), doctor typing indicator, and presence changes.
class ChatSocketService {
  ChatSocketService({this.baseUrl});

  final String? baseUrl;
  IO.Socket? _socket;

  IO.Socket get socket {
    if (_socket == null) {
      throw StateError(
        'Socket has not been initialized. Call connectSocket() first.',
      );
    }
    return _socket!;
  }

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

    // Disconnect existing socket if any
    if (_socket != null) {
      disconnect();
    }

    final domain = (serverUrl != null && serverUrl.isNotEmpty)
        ? serverUrl
        : (baseUrl != null && baseUrl!.isNotEmpty ? baseUrl! : Env.apiBaseUrl);

    final optionsBuilder = IO.OptionBuilder()
        .setTransports(['websocket', 'polling'])
        .setPath('/api/socket/io')
        .enableAutoConnect()
        .enableReconnection();

    if (token != null && token.isNotEmpty) {
      optionsBuilder.setAuth({'token': token});
      optionsBuilder.setExtraHeaders({'Authorization': 'Bearer $token'});
    }

    final newSocket = IO.io(domain, optionsBuilder.build());
    _socket = newSocket;

    // 1. Connection Success
    newSocket.onConnect((_) {
      if (kDebugMode) {
        debugPrint('[ChatSocket] Socket Connected to $domain (thread: $threadId)');
      }
      _connectionStatusController.add(true);
      onConnectionChanged?.call(true);

      // Register User
      newSocket.emit('register_user', {
        'id': patientId,
        'name': patientName,
        'role': 'patient',
      });

      // Join Chat Thread Room
      newSocket.emit('join_thread', {
        'threadId': threadId,
        'user': {
          'id': patientId,
          'name': patientName,
          'role': 'patient',
        },
      });
    });

    // 2. Listen for Incoming Real-Time Messages (<20ms)
    newSocket.on('new_message', (data) {
      if (kDebugMode) {
        debugPrint('[ChatSocket] New Incoming Message: $data');
      }
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

    // 3. Listen for Doctor Typing Status ("Doctor is typing...")
    newSocket.on('typing_status', (data) {
      if (kDebugMode) {
        debugPrint('[ChatSocket] Typing status: $data');
      }
      bool isDoctorTyping = false;
      if (data is Map) {
        isDoctorTyping = data['isTyping'] == true;
      } else if (data is bool) {
        isDoctorTyping = data;
      }
      _typingStatusController.add(isDoctorTyping);
      onDoctorTypingChanged?.call(isDoctorTyping);
    });

    // 4. Listen for Presence (Doctor Online/Offline)
    newSocket.on('presence_change', (data) {
      if (kDebugMode) {
        debugPrint('[ChatSocket] Presence change: $data');
      }
      String status = 'online';
      if (data is Map && data['status'] != null) {
        status = data['status'].toString();
      } else if (data is String) {
        status = data;
      }
      _presenceController.add(status);
      onDoctorPresenceChanged?.call(status);
    });

    // Lifecycle events
    newSocket.onDisconnect((_) {
      if (kDebugMode) {
        debugPrint('[ChatSocket] Socket Disconnected');
      }
      _connectionStatusController.add(false);
      onConnectionChanged?.call(false);
    });

    newSocket.onConnectError((err) {
      if (kDebugMode) {
        debugPrint('[ChatSocket] Connect Error: $err');
      }
    });

    newSocket.onError((err) {
      if (kDebugMode) {
        debugPrint('[ChatSocket] Error: $err');
      }
    });
  }

  // 5. Trigger Typing Event when Patient is typing in Textfield
  void sendTypingStart([String? threadId, String? patientId, String? patientName]) {
    final tid = threadId ?? _currentThreadId;
    final pid = patientId ?? _currentPatientId;
    final pname = patientName ?? _currentPatientName;

    if (tid == null || pid == null || _socket == null || !isConnected) return;

    _socket!.emit('typing_start', {
      'threadId': tid,
      'user': {
        'id': pid,
        'name': pname ?? 'Patient',
        'role': 'patient',
      },
    });
  }

  void sendTypingStop([String? threadId, String? patientId, String? patientName]) {
    final tid = threadId ?? _currentThreadId;
    final pid = patientId ?? _currentPatientId;
    final pname = patientName ?? _currentPatientName;

    if (tid == null || pid == null || _socket == null || !isConnected) return;

    _socket!.emit('typing_stop', {
      'threadId': tid,
      'user': {
        'id': pid,
        'name': pname ?? 'Patient',
        'role': 'patient',
      },
    });
  }

  void disconnect() {
    try {
      _socket?.disconnect();
      _socket?.dispose();
    } catch (_) {}
    _socket = null;
    _connectionStatusController.add(false);
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
