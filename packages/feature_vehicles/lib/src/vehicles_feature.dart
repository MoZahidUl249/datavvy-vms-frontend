import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:vms_catalog/vms_catalog.dart';
import 'package:vms_core/vms_core.dart';
import 'package:vms_design_system/vms_design_system.dart';
import 'package:vms_fleet_records/vms_fleet_records.dart';

import 'data/vehicle_models.dart';
import 'data/vehicle_repository.dart';
import 'ui/detail/vehicle_detail_screen.dart';
import 'ui/detail/vehicle_detail_view_model.dart';
import 'ui/form/vehicle_form_screen.dart';
import 'ui/form/vehicle_form_view_model.dart';
import 'ui/list/vehicle_list_screen.dart';
import 'ui/list/vehicle_list_view_model.dart';

/// `/vehicles`, `/vehicles/new`, `/vehicles/:id` (vehicle page),
/// `/vehicles/:id/edit` and the Fleet sidebar group.
class VehiclesFeature extends FeatureModule {
  VehiclesFeature({
    required ApiClient api,
    required CatalogRepository catalog,
    required UiPreferences preferences,
    required AuthSession session,
    required DocumentRepository documents,
    required MaintenanceRepository maintenance,
    required DriverRepository drivers,
  })  : repository = VehicleRepository(api),
        _catalog = catalog,
        _preferences = preferences,
        _session = session,
        _documents = documents,
        _maintenance = maintenance,
        _drivers = drivers;

  final VehicleRepository repository;
  final DocumentRepository _documents;
  final MaintenanceRepository _maintenance;
  final DriverRepository _drivers;
  final CatalogRepository _catalog;
  final UiPreferences _preferences;
  final AuthSession _session;

  bool get _canManage => _session.user?.canManageFleet ?? false;

  @override
  List<RouteBase> get shellRoutes => [
        GoRoute(
          path: AppRoutes.vehicles,
          pageBuilder: (context, state) {
            final q = state.uri.queryParameters;
            return NoTransitionPage(
              // Key on the query so dashboard links (status=…) rebuild the list.
              key: ValueKey(state.uri.toString()),
              child: VehicleListScreen(
                createViewModel: () => VehicleListViewModel(
                  repository: repository,
                  highlightId: int.tryParse(q['saved'] ?? ''),
                  initialQuery: VehicleQuery(status: StatusFilter.fromApi(q['status'])),
                ),
                catalog: _catalog,
                preferences: _preferences,
                canManage: _canManage,
              ),
            );
          },
        ),
        GoRoute(
          path: AppRoutes.vehicleNew,
          redirect: (context, state) => _canManage ? null : AppRoutes.vehicles,
          pageBuilder: (context, state) => NoTransitionPage(
            child: VehicleFormScreen(
              createViewModel: () => VehicleFormViewModel(repository: repository),
              catalog: _catalog,
              canManage: _canManage,
            ),
          ),
        ),
        GoRoute(
          path: '${AppRoutes.vehicles}/:id',
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return NoTransitionPage(
              key: ValueKey('vehicle-$id-${state.uri.query}'),
              child: id == null
                  ? const _NotFound()
                  : VehicleDetailScreen(
                      createViewModel: () => VehicleDetailViewModel(
                        vehicleId: id,
                        vehicles: repository,
                        documents: _documents,
                        maintenance: _maintenance,
                        drivers: _drivers,
                      ),
                      canManage: _canManage,
                      initialSection: state.uri.queryParameters['section'],
                    ),
            );
          },
        ),
        GoRoute(
          path: '${AppRoutes.vehicles}/:id/edit',
          redirect: (context, state) =>
              _canManage ? null : AppRoutes.vehicleDetail(int.tryParse(state.pathParameters['id'] ?? '') ?? 0),
          pageBuilder: (context, state) {
            final id = int.tryParse(state.pathParameters['id'] ?? '');
            return NoTransitionPage(
              key: ValueKey('vehicle-edit-$id'),
              child: id == null
                  ? const _NotFound()
                  : VehicleFormScreen(
                      createViewModel: () => VehicleFormViewModel(repository: repository, vehicleId: id),
                      catalog: _catalog,
                      canManage: _canManage,
                    ),
            );
          },
        ),
      ];

  @override
  List<NavItem> get navItems => [
        NavItem(
          label: 'Vehicles',
          icon: Icons.local_shipping_outlined,
          path: AppRoutes.vehicles,
          section: 'Fleet',
          order: 10,
          badge: repository.total,
        ),
        if (_canManage)
          const NavItem(
            label: 'Register vehicle',
            icon: Icons.add_circle_outline,
            path: AppRoutes.vehicleNew,
            section: 'Fleet',
            order: 11,
          ),
      ];
}

class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return VmsPage(
      crumbs: [Crumb('Vehicles', onTap: () => context.go(AppRoutes.vehicles)), const Crumb('Not found')],
      title: 'Vehicle not found',
      body: VmsCard(
        child: EmptyState(
          icon: Icons.search_off,
          title: "This vehicle doesn't exist",
          message: 'It may have been deleted. Go back to the list to find it.',
          actionLabel: 'Back to vehicles',
          onAction: () => context.go(AppRoutes.vehicles),
        ),
      ),
    );
  }
}
