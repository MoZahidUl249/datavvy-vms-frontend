import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import 'ui/form/driver_form_screen.dart';
import 'ui/form/driver_form_view_model.dart';
import 'ui/list/driver_list_screen.dart';
import 'ui/list/driver_list_view_model.dart';

/// `/drivers`, `/drivers/new`, `/drivers/:id`.
class DriversFeature extends FeatureModule {
  DriversFeature({required DriverRepository drivers, required AuthSession session})
      : _drivers = drivers,
        _session = session;

  final DriverRepository _drivers;
  final AuthSession _session;

  bool get _canManage => _session.user?.canManageFleet ?? false;

  @override
  List<RouteBase> get shellRoutes => [
        GoRoute(
          path: AppRoutes.drivers,
          pageBuilder: (context, state) {
            final q = state.uri.queryParameters;
            return NoTransitionPage(
              key: ValueKey(state.uri.toString()),
              child: DriverListScreen(
                createViewModel: () => DriverListViewModel(
                  repository: _drivers,
                  initialQuery: DriverQuery(
                    status: q['status'] == null ? null : DriverStatus.fromApi(q['status']),
                    assignment: AssignmentFilter.fromQuery(q['assigned']),
                  ),
                ),
                canManage: _canManage,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.driverNew,
          redirect: (context, state) => _canManage ? null : AppRoutes.drivers,
          pageBuilder: (context, state) => NoTransitionPage(
            child: DriverFormScreen(
              createViewModel: () => DriverFormViewModel(repository: _drivers),
              canManage: _canManage,
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.drivers}/:id',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return NoTransitionPage(
              key: ValueKey('driver-$id'),
              child: DriverFormScreen(
                createViewModel: () => DriverFormViewModel(repository: _drivers, driverId: id ?? -1),
                canManage: _canManage,
              ),
            );
          },
        ),
      ];

  @override
  List<NavItem> get navItems => const [
        NavItem(label: 'Drivers', icon: Icons.badge_outlined, path: AppRoutes.drivers, section: 'Fleet', order: 20),
      ];
}
