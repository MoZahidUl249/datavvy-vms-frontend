import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'session_store.dart';

SessionStore createSessionStore() => _BrowserSessionStore();

/// `window.sessionStorage`, reached through `dart:js_interop` so no extra
/// package is needed. Storage can be blocked (privacy modes, sandboxed
/// frames); every call fails soft, and the app then behaves as before:
/// signed in until reload.
class _BrowserSessionStore implements SessionStore {
  static const _key = 'vms.session';

  JSObject? get _storage {
    try {
      return globalContext['sessionStorage'] as JSObject?;
    } catch (_) {
      return null;
    }
  }

  @override
  String? read() {
    try {
      final v = _storage?.callMethod<JSAny?>('getItem'.toJS, _key.toJS);
      return (v as JSString?)?.toDart;
    } catch (_) {
      return null;
    }
  }

  @override
  void write(String value) {
    try {
      _storage?.callMethod<JSAny?>('setItem'.toJS, _key.toJS, value.toJS);
    } catch (_) {}
  }

  @override
  void clear() {
    try {
      _storage?.callMethod<JSAny?>('removeItem'.toJS, _key.toJS);
    } catch (_) {}
  }
}
