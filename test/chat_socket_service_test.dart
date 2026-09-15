import 'package:flutter_test/flutter_test.dart';
import 'package:altrix/features/patient/data/models/patient_models.dart';
import 'package:altrix/features/patient/data/services/chat_socket_service.dart';

void main() {
  group('ChatSocketService', () {
    test('ChatSocketService initializes streams and handles lifecycle', () {
      final service = ChatSocketService(baseUrl: 'https://test-api.altrixs.com');

      expect(service.isConnected, isFalse);

      // Verify streams can be listened to
      expect(service.onNewMessage, isA<Stream<MessageModel>>());
      expect(service.onTypingStatus, isA<Stream<bool>>());
      expect(service.onPresenceChange, isA<Stream<String>>());
      expect(service.onConnectionChange, isA<Stream<bool>>());

      // Connecting without active server sets up socket instance
      service.connectSocket(
        patientId: 'patient_123',
        patientName: 'John Doe',
        threadId: 'thread_123',
        token: 'test_jwt_token',
      );

      expect(service.socket, isNotNull);

      // Typing start/stop can be invoked safely
      service.sendTypingStart('thread_123', 'patient_123', 'John Doe');
      service.sendTypingStop('thread_123', 'patient_123', 'John Doe');

      // Disconnect cleanly
      service.disconnect();
      expect(service.isConnected, isFalse);

      // Dispose streams
      service.dispose();
    });

    test('MessageModel parses threadId and handles role separation', () {
      final json = {
        'id': 'msg_3',
        'threadId': 'thread_123',
        'senderRole': 'patient',
        'senderName': 'John Doe',
        'body': 'Doctor, can I take the medicine after dinner?',
        'read': false,
        'createdAt': '2026-09-15T10:05:00Z',
      };

      final message = MessageModel.fromJson(json);

      expect(message.id, 'msg_3');
      expect(message.threadId, 'thread_123');
      expect(message.sender, 'patient');
      expect(message.senderName, 'John Doe');
      expect(message.body, 'Doctor, can I take the medicine after dinner?');
      expect(message.isRead, isFalse);
      expect(message.isFromMe(), isTrue);

      final clinicianJson = {
        'id': 'msg_1',
        'threadId': 'thread_123',
        'senderRole': 'clinician',
        'senderName': 'Dr. Sarah Smith',
        'body': 'Hello John, how are you feeling today?',
        'read': true,
        'createdAt': '2026-09-15T10:00:00Z',
      };

      final clinicianMsg = MessageModel.fromJson(clinicianJson);
      expect(clinicianMsg.id, 'msg_1');
      expect(clinicianMsg.threadId, 'thread_123');
      expect(clinicianMsg.sender, 'clinician');
      expect(clinicianMsg.senderName, 'Dr. Sarah Smith');
      expect(clinicianMsg.isFromMe(), isFalse);
      expect(clinicianMsg.initials, 'DS');
    });
  });
}
