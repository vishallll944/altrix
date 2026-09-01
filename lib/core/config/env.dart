/// App environment values.
///
/// Set the API URL when your backend is ready:
/// `flutter run --dart-define=API_BASE_URL=https://your-api.com/v1`
class Env {
  const Env._();

  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );

  static bool get isApiConfigured => apiBaseUrl.isNotEmpty;
}
