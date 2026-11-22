/// Build-time configuration, injected with `--dart-define`.
///
/// ```sh
/// flutter run -d chrome --dart-define=VMS_API_BASE_URL=http://localhost:8080/api
/// ```
class AppConfig {
  const AppConfig({required this.apiBaseUrl});

  /// Reads `VMS_API_BASE_URL`; defaults to the local backend.
  factory AppConfig.fromEnvironment() => const AppConfig(
        apiBaseUrl: String.fromEnvironment(
          'VMS_API_BASE_URL',
          defaultValue: 'http://localhost:8080/api',
        ),
      );

  /// Base URL without the version segment, e.g. `http://localhost:8080/api`.
  final String apiBaseUrl;
}
