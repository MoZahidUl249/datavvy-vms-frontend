import 'session_store_memory.dart'
    if (dart.library.js_interop) 'session_store_web.dart' as impl;

/// Where the signed-in session survives a page reload.
///
/// On the web this is the tab's `sessionStorage`: it is cleared when the tab
/// closes and is not shared with other tabs. Elsewhere (unit tests on the VM)
/// it is a no-op in-memory store.
abstract interface class SessionStore {
  String? read();
  void write(String value);
  void clear();
}

/// The store for the current platform.
SessionStore defaultSessionStore() => impl.createSessionStore();

/// Keeps the value for the life of the object only. Used in tests.
class MemorySessionStore implements SessionStore {
  String? _value;

  @override
  String? read() => _value;

  @override
  void write(String value) => _value = value;

  @override
  void clear() => _value = null;
}
