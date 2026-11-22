import 'json.dart';

/// Client-side view of the backend's RFC 9457 problem document.
///
/// Branch on [code] (stable contract), never on [message] (human text).
class ApiError {
  const ApiError({
    required this.status,
    required this.code,
    required this.message,
    this.fieldErrors = const {},
    this.details = const {},
  });

  /// No response at all (offline, CORS, server down, timeout).
  factory ApiError.network() => const ApiError(
        status: 0,
        code: 'NETWORK',
        message: "Can't reach the server. Check your connection and try again.",
      );

  /// Builds an error from a non-2xx response body (may be null or not JSON).
  factory ApiError.fromResponse(int status, Object? body) {
    final map = body is Map ? asMap(body) : const <String, dynamic>{};
    final fields = <String, String>{};
    final rawFields = map['fieldErrors'];
    if (rawFields is List) {
      for (final f in rawFields) {
        if (f is Map) {
          final m = asMap(f);
          final field = m['field'];
          final message = m['message'];
          if (field is String && message is String) {
            fields.putIfAbsent(field, () => message);
          }
        }
      }
    }
    final details = map['details'];
    return ApiError(
      status: status,
      code: map['code'] is String ? map['code'] as String : 'HTTP_$status',
      message: map['detail'] is String
          ? map['detail'] as String
          : 'Something went wrong (HTTP $status). Try again.',
      fieldErrors: fields,
      details: details is Map ? asMap(details) : const {},
    );
  }

  final int status;
  final String code;
  final String message;

  /// field name → message, for showing errors under form fields.
  final Map<String, String> fieldErrors;
  final Map<String, dynamic> details;

  bool get isNetwork => status == 0;
  bool get isConflict => status == 409;
  bool get isValidation => code == 'VALIDATION_FAILED';

  @override
  String toString() => 'ApiError($status, $code, $message)';
}
