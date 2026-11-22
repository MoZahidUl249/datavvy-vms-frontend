import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';

import 'data/dashboard_repository.dart';
import 'ui/dashboard_screen.dart';
import 'ui/dashboard_view_model.dart';

class DashboardFeature extends FeatureModule {
  DashboardFeature({required ApiClient api, required UiPreferences preferences, required AuthSession session})
      : _repository = DashboardRepository(api),
        _preferences = preferences,
        _session = session;

  final DashboardRepository _repository;
  final UiPreferences _preferences;
  final AuthSession _session;

  @override
  List<RouteBase> get shellRoutes => [
        GoRoute(
          path: AppRoutes.dashboard,
          pageBuilder: (context, state) => NoTransitionPage(
            child: DashboardScreen(
              createViewModel: () => DashboardViewModel(_repository),
              preferences: _preferences,
              canManageFleet: _session.user?.canManageFleet ?? false,
            ),
          ),
        ),
      ];

  @override
  List<NavItem> get navItems => const [
        NavItem(label: 'Dashboard', icon: Icons.space_dashboard_outlined, path: AppRoutes.dashboard, order: 0),
      ];
}
