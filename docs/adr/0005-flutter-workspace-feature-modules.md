# ADR-0005: Flutter pub workspace with feature modules

**Status:** accepted · 2026-11-21

## Decision
The Flutter app is a pub workspace: `vms_core`, `vms_design_system`, data
packages and one `feature_*` package per area. Each feature implements
`FeatureModule` (routes + sidebar items); `lib/main.dart` composes them. MVVM
with `ChangeNotifier` view models and repositories returning `Result<T>`
(Flutter team's architecture guidance). No code generation, no global service
locator: dependencies are passed explicitly.

## Consequences
+ Teams own packages; boundaries are visible in `pubspec.yaml`.
+ One lock file, one `flutter pub get`.
+ New feature = new package + one line in `main.dart`.
− Shared packages (`vms_core`, design system) need careful review — CODEOWNERS.
