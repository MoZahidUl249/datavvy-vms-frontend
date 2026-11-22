import 'dart:convert';

import 'package:flutter/foundation.dart';

import '../api/api_client.dart';
import 'session_store.dart';

/// The signed-in user, as returned by `POST /v1/auth/login`.
@immutable
class SessionUser {
  const SessionUser({
    required this.id,
    required this.email,
    required this.displayName,
    required this.role,
  });

  final int id;
  final String email;
  final String displayName;

  /// `ADMIN`, `FLEET_MANAGER` or `VIEWER`.
  final String role;

  bool get isAdmin => role == 'ADMIN';
  bool get canManageFleet => role == 'ADMIN' || role == 'FLEET_MANAGER';

  String get roleLabel => switch (role) {
        'ADMIN' => 'Admin',
        'FLEET_MANAGER' => 'Fleet manager',
        _ => 'Viewer',
      };

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    return parts.take(2).map((p) => p[0].toUpperCase()).join();
  }
}

/// App-wide sign-in state. The router listens to it to redirect.
///
/// The session is kept in a [SessionStore] (the tab's `sessionStorage` on
/// the web) so a page reload keeps you signed in until the token expires or
/// the tab closes. Pass a [MemorySessionStore] in tests.
class AuthSession extends ChangeNotifier implements TokenProvider {
  AuthSession({SessionStore? store}) : _store = store ?? defaultSessionStore() {
    _restore();
  }

  final SessionStore _store;
  String? _token;
  DateTime? _expiresAt;
  SessionUser? _user;
  bool _expired = false;

  SessionUser? get user => _user;

  /// True when the last sign-out happened because the token expired.
  bool get endedByExpiry => _expired;

  bool get isSignedIn => token != null && _user != null;

  @override
  String? get token {
    final expiresAt = _expiresAt;
    if (_token == null || (expiresAt != null && DateTime.now().isAfter(expiresAt))) {
      return null;
    }
    return _token;
  }

  void signIn({required String token, required SessionUser user, required int expiresInSeconds}) {
    _token = token;
    _user = user;
    _expiresAt = DateTime.now().add(Duration(seconds: expiresInSeconds));
    _expired = false;
    _persist();
    notifyListeners();
  }

  void signOut({bool expired = false}) {
    if (_token == null && _user == null) return;
    _token = null;
    _user = null;
    _expiresAt = null;
    _expired = expired;
    _store.clear();
    notifyListeners();
  }

  void _persist() {
    final user = _user;
    if (_token == null || user == null || _expiresAt == null) return;
    _store.write(jsonEncode({
      'token': _token,
      'expiresAt': _expiresAt!.toUtc().toIso8601String(),
      'user': {'id': user.id, 'email': user.email, 'displayName': user.displayName, 'role': user.role},
    }));
  }

  /// Anything unreadable, incomplete or expired is discarded.
  void _restore() {
    final raw = _store.read();
    if (raw == null) return;
    try {
      final m = jsonDecode(raw) as Map<String, dynamic>;
      final expiresAt = DateTime.parse(m['expiresAt'] as String).toLocal();
      final u = m['user'] as Map<String, dynamic>;
      if (DateTime.now().isAfter(expiresAt)) {
        _store.clear();
        return;
      }
      _token = m['token'] as String;
      _expiresAt = expiresAt;
      _user = SessionUser(
        id: (u['id'] as num).toInt(),
        email: u['email'] as String,
        displayName: u['displayName'] as String,
        role: u['role'] as String,
      );
    } catch (_) {
      _store.clear();
    }
  }
}
