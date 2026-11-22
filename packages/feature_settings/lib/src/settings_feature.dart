import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_catalog/vms_catalog.dart';
import 'package:vms_core/vms_core.dart';

import 'settings_screen.dart';

class SettingsFeature extends FeatureModule {
  SettingsFeature({required CatalogRepository catalog, required UiPreferences preferences, required AuthSession session})
      : _catalog = catalog,
        _preferences = preferences,
        _session = session;

  final CatalogRepository _catalog;
  final UiPreferences _preferences;
  final AuthSession _session;

  @override
  List<RouteBase> get shellRoutes => [
        GoRoute(
          path: AppRoutes.settings,
          pageBuilder: (context, state) => NoTransitionPage(
            key: ValueKey(state.uri.toString()),
            child: SettingsScreen(
              catalog: _catalog,
              preferences: _preferences,
              isAdmin: _session.user?.isAdmin ?? false,
              initialSection: state.uri.queryParameters['section'],
            ),
          ),
        ),
      ];

  @override
  List<NavItem> get navItems => const [
        NavItem(label: 'Settings', icon: Icons.settings_outlined, path: AppRoutes.settings, section: 'Workspace', order: 90),
      ];
}
