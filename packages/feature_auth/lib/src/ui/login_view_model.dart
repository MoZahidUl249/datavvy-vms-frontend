import 'package:flutter/foundation.dart';
import 'package:vms_core/vms_core.dart';

import '../data/auth_repository.dart';

/// State + commands for the sign-in screen.
class LoginViewModel extends ChangeNotifier {
  LoginViewModel({required AuthRepository repository, required AuthSession session})
      : _repository = repository,
        _session = session;

  final AuthRepository _repository;
  final AuthSession _session;

  String email = '';
  String password = '';
  bool submitting = false;
  bool _attempted = false;

  /// Banner message (wrong credentials, network).
  String? bannerError;

  bool get sessionExpired => _session.endedByExpiry;

  String? get emailError {
    if (!_attempted) return null;
    final value = email.trim();
    if (value.isEmpty) return 'Enter your email, like name@company.com.';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Enter a valid email, like name@company.com.';
    }
    return null;
  }

  String? get passwordError => _attempted && password.isEmpty ? 'Enter your password.' : null;

  void setEmail(String value) {
    email = value;
    bannerError = null;
    notifyListeners();
  }

  void setPassword(String value) {
    password = value;
    bannerError = null;
    notifyListeners();
  }

  /// Returns true when signed in (the router then redirects).
  Future<bool> submit() async {
    _attempted = true;
    bannerError = null;
    if (emailError != null || passwordError != null) {
      notifyListeners();
      return false;
    }
    submitting = true;
    notifyListeners();

    final result = await _repository.login(email: email, password: password);
    submitting = false;
    switch (result) {
      case Ok(:final value):
        _session.signIn(token: value.token, user: value.user, expiresInSeconds: value.expiresIn);
        notifyListeners();
        return true;
      case Err(:final error):
        bannerError = error.code == 'INVALID_CREDENTIALS'
            ? "That email and password don't match. Check both and try again."
            : error.message;
        notifyListeners();
        return false;
    }
  }
}
