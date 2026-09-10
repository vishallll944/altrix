import 'dart:convert';

import 'package:altrix/core/network/api_exception.dart';
import 'package:altrix/core/network/api_response.dart';
import 'package:altrix/features/auth/data/models/client_model.dart';
import 'package:dio/dio.dart';
import 'package:altrix/features/auth/data/models/update_profile_request.dart';
import 'package:altrix/features/patient/data/datasources/patient_remote_datasource.dart';
import 'package:altrix/features/patient/data/models/patient_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Standard Error Format Extraction', () {
    test('extracts error message with field-level details', () {
      final payload = {
        'success': false,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Invalid credentials or request data',
          'fields': {
            'email': 'Invalid email address',
          },
        },
      };

      final message = extractApiErrorMessage(payload);
      expect(message, contains('Invalid credentials or request data'));
      expect(message, contains('email: Invalid email address'));
    });

    test('extracts error message when error is a plain string', () {
      final payload = {
        'success': false,
        'error': 'Unauthorized access',
      };

      final message = extractApiErrorMessage(payload);
      expect(message, 'Unauthorized access');
    });

    test('extracts error code and message from standard error structure', () {
      final payload = {
        'success': false,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Invalid request',
        },
      };

      final code = extractApiErrorCode(payload);
      final message = extractApiErrorMessage(payload);

      expect(code, 'VALIDATION_ERROR');
      expect(message, 'Invalid request');
    });

    test('requireApiSuccess throws ApiException with code and message', () {
      final payload = {
        'success': false,
        'error': {
          'code': 'VALIDATION_ERROR',
          'message': 'Invalid request',
        },
      };

      try {
        requireApiSuccess(payload);
        fail('Should have thrown ApiException');
      } on ApiException catch (e) {
        expect(e.code, 'VALIDATION_ERROR');
        expect(e.message, 'Invalid request');
        expect(e.isValidationError, isTrue);
      }
    });
  });

  group('Update Profile Request', () {
    test('only includes changed / non-null fields in JSON body', () {
      const request = UpdateProfileRequest(
        phone: '+14105550199',
        addressLine1: '456 New Ave',
        city: 'Baltimore',
        emergencyContactName: 'Jane Doe',
        emergencyContactPhone: '+14105550101',
      );

      final json = request.toJson();
      expect(json, {
        'phone': '+14105550199',
        'addressLine1': '456 New Ave',
        'city': 'Baltimore',
        'emergencyContactName': 'Jane Doe',
        'emergencyContactPhone': '+14105550101',
      });
      expect(json.containsKey('name'), isFalse);
      expect(json.containsKey('email'), isFalse);
      expect(json.containsKey('state'), isFalse);
      expect(json.containsKey('postalCode'), isFalse);
    });
  });

  group('PatientFormModel Parsing', () {
    test('parses pending and signed status correctly', () {
      final pendingJson = {
        'id': 'form_1',
        'title': 'HIPAA Consent Form',
        'status': 'pending',
        'description': 'Annual privacy agreement',
        'dueDate': '2026-09-30T00:00:00.000Z',
      };

      final model = PatientFormModel.fromJson(pendingJson);
      expect(model.id, 'form_1');
      expect(model.title, 'HIPAA Consent Form');
      expect(model.isPending, isTrue);
      expect(model.isSigned, isFalse);
      expect(model.isExpired, isFalse);

      final signedModel = PatientFormModel.fromJson({
        'id': 'form_2',
        'title': 'Intake Questionnaire',
        'status': 'signed',
      });
      expect(signedModel.isSigned, isTrue);
      expect(signedModel.isPending, isFalse);
    });
  });

  group('ClientModel & Telehealth Model Parsing', () {
    test('parses nested address and emergencyContact objects', () {
      final json = {
        'id': 'p_123',
        'name': 'Rahul Sharma',
        'email': 'rahul@example.com',
        'phone': '+14155552671',
        'address': {
          'line1': '789 Market St',
          'city': 'San Francisco',
          'state': 'CA',
          'postalCode': '94103',
        },
        'emergencyContact': {
          'name': 'Pooja Sharma',
          'phone': '+14155559999',
        },
      };

      final client = ClientModel.fromJson(json);
      expect(client.id, 'p_123');
      expect(client.name, 'Rahul Sharma');
      expect(client.addressLine1, '789 Market St');
      expect(client.city, 'San Francisco');
      expect(client.state, 'CA');
      expect(client.postalCode, '94103');
      expect(client.emergencyContactName, 'Pooja Sharma');
      expect(client.emergencyContactPhone, '+14155559999');
    });

    test('parses TelehealthSessionModel with Zoom join link', () {
      final json = {
        'provider': 'zoom',
        'joinUrl': 'https://zoom.us/j/1234567890?pwd=abc',
        'status': 'ready',
      };

      final session = TelehealthSessionModel.fromJson(json);
      expect(session.provider, 'zoom');
      expect(session.joinUrl, 'https://zoom.us/j/1234567890?pwd=abc');
      expect(session.status, 'ready');
    });
  });

  group('Dio JSON Request Serialization', () {
    test('verifies Dio serializes Map to valid JSON when contentType is configured', () async {
      final dio = Dio(BaseOptions(
        contentType: 'application/json',
      ));
      final options = RequestOptions(
        path: '/api/patient/login',
        data: {'email': 'user@example.com', 'password': 'secret'},
        contentType: dio.options.contentType,
      );
      final body = await dio.transformer.transformRequest(options);
      expect(body, '{"email":"user@example.com","password":"secret"}');
    });
  });

  group('Patient Check-in API Contract', () {
    test('createCheckIn sends expected json payload with mood, stress, sleep, journal', () async {
      RequestOptions? capturedOptions;
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            capturedOptions = options;
            return handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 201,
                data: {
                  'success': true,
                  'data': {
                    'checkIn': {
                      'id': 'chk_123',
                      'mood': 8,
                      'stress': 3,
                      'sleep': 7,
                      'journal': 'Feeling much better today and rested well.',
                      'createdAt': '2026-09-10T13:30:00.000Z',
                    },
                  },
                },
              ),
            );
          },
        ),
      );

      final dataSource = PatientRemoteDataSource(dio);
      final checkIn = await dataSource.createCheckIn(
        mood: 8,
        stress: 3,
        sleep: 7,
        journal: 'Feeling much better today and rested well.',
      );

      expect(checkIn.id, 'chk_123');
      expect(checkIn.mood, 8);
      expect(checkIn.stress, 3);
      expect(checkIn.sleep, 7);
      expect(checkIn.journal, 'Feeling much better today and rested well.');

      expect(capturedOptions, isNotNull);
      expect(capturedOptions!.path, '/api/patient/check-ins');
      expect(capturedOptions!.method, 'POST');
      final decodedData = jsonDecode(capturedOptions!.data as String) as Map<String, dynamic>;
      expect(decodedData, {
        'mood': 8,
        'stress': 3,
        'sleep': 7,
        'journal': 'Feeling much better today and rested well.',
      });
      expect(capturedOptions!.headers['Content-Type'], 'application/json');
      expect(capturedOptions!.headers['Accept'], 'application/json');
    });
  });
}
