/// Shared kernel for every VMS client package.
///
/// Keep it free of UI and of feature logic: config, HTTP, session, routing
/// contracts and workspace preferences only.
library;

export 'src/api/api_client.dart';
export 'src/api/api_error.dart';
export 'src/api/json.dart';
export 'src/api/result.dart';
export 'src/auth/auth_session.dart';
export 'src/auth/session_store.dart' show SessionStore, MemorySessionStore;
export 'src/config/app_config.dart';
export 'src/feature/feature_module.dart';
export 'src/format/formatters.dart';
export 'src/preferences/ui_preferences.dart';
export 'src/routing/app_routes.dart';
