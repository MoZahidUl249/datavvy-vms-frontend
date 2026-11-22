import 'package:vms_core/vms_core.dart';

class LoginResult {
  const LoginResult({required this.token, required this.expiresIn, required this.user});
  final String token;
  final int expiresIn;
  final SessionUser user;
}

/// Talks to `/v1/auth/*`.
class AuthRepository {
  const AuthRepository(this._api);

  final ApiClient _api;

  Future<Result<LoginResult>> login({required String email, required String password}) async {
    final result = await _api.post('/v1/auth/login', body: {'email': email.trim(), 'password': password});
    return result.map((json) {
      final map = asMap(json);
      final user = asMap(map['user']);
      return LoginResult(
        token: asString(map['accessToken']),
        expiresIn: asInt(map['expiresIn'], 3600),
        user: SessionUser(
          id: asInt(user['id']),
          email: asString(user['email']),
          displayName: asString(user['displayName']),
          role: asString(user['role'], 'VIEWER'),
        ),
      );
    });
  }
}
