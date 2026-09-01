import 'package:altrix/features/auth/data/datasources/auth_session_storage.dart';

class FakeAuthSessionStorage implements AuthSessionStorage {
  FakeAuthSessionStorage({this.storedToken});

  String? storedToken;

  @override
  Future<void> clearToken() async {
    storedToken = null;
  }

  @override
  Future<String?> readToken() async => storedToken;

  @override
  Future<void> saveToken(String token) async {
    storedToken = token;
  }
}
