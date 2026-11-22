---
name: new-flutter-feature
description: Creates a new Flutter feature package in the frontend pub workspace (data, view models, screens, FeatureModule with routes and sidebar items) and wires it into the app shell. Use when adding a new screen area such as maintenance or drivers, or when the user types /new-flutter-feature.
---

# Add a Flutter feature package

Example: **feature_maintenance**.

## 1. Package

```
packages/feature_maintenance/
├── pubspec.yaml            # resolution: workspace; deps: flutter, material_ui, go_router, vms_core, vms_design_system
├── lib/feature_maintenance.dart     # exports only the module (+ models other code needs)
├── lib/src/data/maintenance_models.dart      # fromJson/toJson = contract schemas
├── lib/src/data/maintenance_repository.dart  # ApiClient → Result<T>
├── lib/src/ui/list/maintenance_list_screen.dart
├── lib/src/ui/list/maintenance_list_view_model.dart
├── lib/src/maintenance_feature.dart          # FeatureModule
└── test/maintenance_list_view_model_test.dart
```

Copy `packages/feature_dashboard/pubspec.yaml` as the starting point.

## 2. Register in the workspace

`pubspec.yaml`:
```yaml
workspace:
  - packages/feature_maintenance
dependencies:
  feature_maintenance:
    path: packages/feature_maintenance
```
Then `cd frontend && flutter pub get`.

## 3. FeatureModule

```dart
class MaintenanceFeature extends FeatureModule {
  MaintenanceFeature({required ApiClient api, required AuthSession session})
      : _repository = MaintenanceRepository(api), _session = session;

  final MaintenanceRepository _repository;
  final AuthSession _session;

  @override
  List<RouteBase> get shellRoutes => [
        GoRoute(
          path: '/maintenance',
          pageBuilder: (context, state) => NoTransitionPage(
            child: MaintenanceListScreen(createViewModel: () => MaintenanceListViewModel(_repository)),
          ),
        ),
      ];

  @override
  List<NavItem> get navItems => const [
        NavItem(label: 'Maintenance', icon: Icons.build_outlined, path: '/maintenance', section: 'Fleet', order: 20),
      ];
}
```

Add the path constant to `vms_core/lib/src/routing/app_routes.dart` if other
features link to it. Then add one line in `lib/main.dart`:
`MaintenanceFeature(api: api, session: session),`

## 4. Screen pattern

- `StatefulWidget` with `late final _vm = widget.createViewModel()..load();`,
  dispose it in `dispose()`, rebuild with `ListenableBuilder`.
- Wrap in `VmsPage(crumbs:, title:, subtitle:, actions:, body:)`.
- States: skeleton while loading, `EmptyState` (first run + no results),
  `ErrorBanner` with "Try again".
- Follow `.agents/skills/vms-ui/SKILL.md`; design the screen on the canvas first
  if it doesn't exist (new page V9…).

## 5. Ownership

`.github/CODEOWNERS` → `/packages/feature_maintenance/ @datavvy/<team>`.

## 6. Verify

`/verify` — analyzer clean, package tests pass, screen checked in Chrome.
