---
trigger: glob
globs: "**/*.dart, **/pubspec.yaml"
description: "Flutter workspace, package boundary and MVVM conventions."
---

# Flutter rules

- Web only: no `dart:io`, no mobile/desktop platform folders or plugins without web support.
- Import Material as `package:material_ui/material_ui.dart`.
- Feature packages never import other feature packages. Shared code goes to
  `vms_core` (no UI), `vms_design_system` (UI) or a data package (`vms_catalog`).
- MVVM: `*_screen.dart` (StatefulWidget that owns a `ChangeNotifier` view model
  from a `createViewModel` factory) + `*_view_model.dart`. No HTTP in widgets.
- Repositories return `Result<T>`; branch on `ApiError.code`, not on text.
- Models: hand-written `fromJson`/`toJson` that match `contracts/openapi/vms-api.yaml` in the backend repo.
- Navigation only via `AppRoutes` constants and `context.go(...)`.
- After `await` in a widget, check `mounted` / `context.mounted` before using context.
- New dependency → add to the package's `pubspec.yaml`, run `flutter pub get` at
  the repo root (workspace root), mention it in the plan.
- `dart format .` and `flutter analyze` must be clean before you finish.
