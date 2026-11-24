import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import 'maintenance_screen.dart';
import 'maintenance_view_model.dart';

/// `/maintenance`
class MaintenanceFeature extends FeatureModule {
  MaintenanceFeature({required MaintenanceRepository maintenance}) : _maintenance = maintenance;

  final MaintenanceRepository _maintenance;

  @override
  List<RouteBase> get shellRoutes => [
        GoRoute(
          path: AppRoutes.maintenance,
          pageBuilder: (context, state) => NoTransitionPage(
            child: MaintenanceScreen(createViewModel: () => MaintenanceViewModel(repository: _maintenance)),
          ),
        ),
      ];

  @override
  List<NavItem> get navItems => const [
        NavItem(label: 'Maintenance', icon: Icons.build_outlined, path: AppRoutes.maintenance, section: 'Fleet', order: 40),
      ];
}
