import 'package:altrix/core/network/api_exception.dart';
import 'package:altrix/features/auth/data/models/update_profile_request.dart';
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

    test('extracts message from top-level message string', () {
      final payload = {
        'success': false,
        'message': 'Resource not found',
      };

      final message = extractApiErrorMessage(payload);
      expect(message, 'Resource not found');
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
}
