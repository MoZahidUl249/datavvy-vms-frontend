import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import 'api_error.dart';
import 'result.dart';

/// Supplies the bearer token for each request (implemented by `AuthSession`).
abstract interface class TokenProvider {
  String? get token;
}

/// Thin JSON-over-HTTP client for the VMS API.
///
/// * Paths are relative to `{apiBaseUrl}` and include the version: `/v1/vehicles`.
/// * Returns [Result]: `Ok(decodedJson)` for 2xx, `Err(ApiError)` otherwise.
/// * A 401 on an authenticated call triggers [onUnauthorized] (session expired).
class ApiClient {
  ApiClient({
    required AppConfig config,
    required TokenProvider tokens,
    http.Client? httpClient,
    this.timeout = const Duration(seconds: 20),
  })  : _config = config,
        _tokens = tokens,
        _http = httpClient ?? http.Client();

  final AppConfig _config;
  final TokenProvider _tokens;
  final http.Client _http;
  final Duration timeout;

  /// Called when the server rejects our token. Wired by the app shell.
  void Function()? onUnauthorized;

  Future<Result<Object?>> get(String path, {Map<String, Object?>? query}) =>
      _send('GET', path, query: query);

  Future<Result<Object?>> post(String path, {Object? body}) =>
      _send('POST', path, body: body);

  Future<Result<Object?>> put(String path, {Object? body}) =>
      _send('PUT', path, body: body);

  Future<Result<Object?>> patch(String path, {Object? body}) =>
      _send('PATCH', path, body: body);

  Future<Result<Object?>> delete(String path) => _send('DELETE', path);

  Uri uri(String path, [Map<String, Object?>? query]) {
    final params = <String, dynamic>{};
    query?.forEach((key, value) {
      if (value == null) return;
      if (value is Iterable) {
        final list = value.map((v) => '$v').toList();
        if (list.isNotEmpty) params[key] = list;
      } else {
        final s = '$value';
        if (s.isNotEmpty) params[key] = s;
      }
    });
    final base = Uri.parse('${_config.apiBaseUrl}$path');
    return params.isEmpty ? base : base.replace(queryParameters: params);
  }

  Future<Result<Object?>> _send(
    String method,
    String path, {
    Map<String, Object?>? query,
    Object? body,
  }) async {
    final token = _tokens.token;
    final headers = <String, String>{
      'Accept': 'application/json',
      if (body != null) 'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
    final target = uri(path, query);
    final encoded = body == null ? null : jsonEncode(body);

    http.Response response;
    try {
      final Future<http.Response> call = switch (method) {
        'GET' => _http.get(target, headers: headers),
        'POST' => _http.post(target, headers: headers, body: encoded),
        'PUT' => _http.put(target, headers: headers, body: encoded),
        'PATCH' => _http.patch(target, headers: headers, body: encoded),
        'DELETE' => _http.delete(target, headers: headers),
        _ => throw ArgumentError('Unsupported method $method'),
      };
      response = await call.timeout(timeout);
    } on TimeoutException {
      return Err(ApiError.network());
    } on http.ClientException {
      return Err(ApiError.network());
    }

    final decoded = _decode(response);
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return Ok(decoded);
    }
    if (response.statusCode == 401 && token != null) {
      onUnauthorized?.call();
    }
    return Err(ApiError.fromResponse(response.statusCode, decoded));
  }

  static Object? _decode(http.Response response) {
    if (response.body.isEmpty) return null;
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      return null;
    }
  }
}
