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

    test('parses exact user backend response', () {
      final response = LoginResponse.fromJson({
        'success': true,
        'data': {
          'token':
              'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJjbXRpZDNwOWowMDAzcWZ3bTlscm4zdXNuIiwiY2xpZW50SWQiOiJjbXRpZDNwOWEwMDAxcWZ3bWIwc3VrNWk5IiwidHlwIjoicGF0aWVudCIsImNyZWRlbnRpYWwiOiI0MzA5YjkxMTg0MGY2MWVmZDJhNmJhMzJjY2U3ZjA2Mjk3ZDg1OWY1ODBjMDJjZTkxZDNjN2I4YmU1ZjIxY2RmIiwiaWF0IjoxNzg5MDI1NTQwLCJleHAiOjE3OTE2MTc1NDB9.riFImYugJxrG_Kfy8XzW5yTtcEuEA1mAWwPt-uVUqik',
          'client': {
            'id': 'cmtid3p9a0001qfwmb0suk5i9',
            'name': 'vishal',
            'email': 'vishal@mindaptix.com',
            'phone': '7677876767675',
          },
        },
      });

      expect(response.token, startsWith('eyJhbGci'));
      expect(response.client.id, 'cmtid3p9a0001qfwmb0suk5i9');
      expect(response.client.name, 'vishal');
      expect(response.client.email, 'vishal@mindaptix.com');
      expect(response.client.phone, '7677876767675');
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

    test('parses avatarUrl from image field and resolves relative url', () {
      final response = ProfileResponse.fromJson({
        'success': true,
        'data': {
          'client': {
            'id': 'cmtid3p9a0001qfwmb0suk5i9',
            'name': 'vishal',
            'email': 'vishal@mindaptix.com',
            'phone': '7591033162',
            'image':
                '/uploads/client-avatars/cmtid3p9a0001qfwmb0suk5i9.webp?v=1789377565395',
          },
        },
      });

      expect(
        response.client.avatarUrl,
        'https://altrixs.com/uploads/client-avatars/cmtid3p9a0001qfwmb0suk5i9.webp?v=1789377565395',
      );
      final entity = response.client.toEntity();
      expect(
        entity.avatarUrl,
        'https://altrixs.com/uploads/client-avatars/cmtid3p9a0001qfwmb0suk5i9.webp?v=1789377565395',
      );
    });
  });
}
