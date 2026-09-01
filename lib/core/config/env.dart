/// Set when your backend is ready:
/// `flutter run --dart-define=API_BASE_URL=https://your-domain.com`
class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;
}
