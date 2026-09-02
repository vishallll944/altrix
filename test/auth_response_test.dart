import 'package:altrix/features/auth/data/models/login_response.dart';
import 'package:altrix/features/auth/data/models/profile_response.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoginResponse', () {
    test('parses nested data payload', () {
      final response = LoginResponse.fromJson({
        'success': true,
        'data': {
          'token': 'jwt-token',
          'client': {
            'id': 'user-1',
            'name': 'vishal',
            'email': 'vishal@mindaptix.com',
            'phone': '7677876767675',
          },
        },
      });

      expect(response.token, 'jwt-token');
      expect(response.client.email, 'vishal@mindaptix.com');
    });

    test('parses flat payload', () {
      final response = LoginResponse.fromJson({
        'success': true,
        'token': 'jwt-token',
        'client': {
          'id': 'user-1',
          'name': 'vishal',
          'email': 'vishal@mindaptix.com',
          'phone': '7677876767675',
        },
      });

      expect(response.token, 'jwt-token');
      expect(response.client.name, 'vishal');
    });
  });

  group('ProfileResponse', () {
    test('parses nested data payload with client object', () {
      final response = ProfileResponse.fromJson({
        'success': true,
        'data': {
          'client': {
            'id': 'user-1',
            'name': 'vishal',
            'email': 'vishal@mindaptix.com',
            'phone': '7677876767675',
          },
        },
      });

      expect(response.client.email, 'vishal@mindaptix.com');
    });

    test('parses nested data payload with client fields directly', () {
      final response = ProfileResponse.fromJson({
        'success': true,
        'data': {
          'id': 'user-1',
          'name': 'vishal',
          'email': 'vishal@mindaptix.com',
          'phone': '7677876767675',
        },
      });

      expect(response.client.name, 'vishal');
    });
  });
}
