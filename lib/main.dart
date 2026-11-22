import 'package:feature_auth/feature_auth.dart';
import 'package:feature_dashboard/feature_dashboard.dart';
import 'package:feature_settings/feature_settings.dart';
import 'package:feature_vehicles/feature_vehicles.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_catalog/vms_catalog.dart';
import 'package:vms_core/vms_core.dart';

import 'app/vms_app.dart';

/// Composition root: the only place that knows every package.
///
/// Adding a feature = create its package, then add one line to [features].
void main() {
  // Clean browser URLs (/vehicles/12) instead of hash URLs (/#/vehicles/12).
  // The web server must fall back to index.html for unknown paths (see frontend/nginx.conf).
  usePathUrlStrategy();

  final session = AuthSession();
  final api = ApiClient(config: AppConfig.fromEnvironment(), tokens: session)
    ..onUnauthorized = () => session.signOut(expired: true);
  final catalog = CatalogRepository(api);
  final preferences = UiPreferences();

  final features = <FeatureModule>[
    AuthFeature(api: api, session: session),
    DashboardFeature(api: api, preferences: preferences, session: session),
    VehiclesFeature(api: api, catalog: catalog, preferences: preferences, session: session),
    SettingsFeature(catalog: catalog, preferences: preferences, session: session),
  ];

  runApp(VmsApp(session: session, features: features));
}
