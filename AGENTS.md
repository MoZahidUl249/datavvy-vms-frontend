# Datavvy VMS web app — agent guide

Read this first. It applies to every agent (Antigravity, Claude Code, Codex,
Cursor …) and every human working in this repo.

**This repo:** the web app — Flutter **Web only** · Dart ≥ 3.14 · pub workspace ·
`material_ui` · `go_router` · MVVM with `ChangeNotifier`.
**The API** lives in [datavvy-vms-backend](https://github.com/MoZahidUl249/datavvy-vms-backend),
which owns the contract (`contracts/openapi/vms-api.yaml`). Dart models must
match it field for field.

## Repo map

```
AGENTS.md            ← you are here (always loaded)
.agents/rules/       ← scoped rules (load by file glob)
.agents/skills/      ← playbooks; each is also a /slash-command
.agents/agents/      ← read-only reviewer subagents
lib/                 ← app shell: main.dart (composition root), router, sidebar
packages/            ← vms_core · vms_design_system · vms_catalog · feature_*
layout/              ← V8 design canvas export (design source, read-only)
docs/                ← screenshots, demo video, ADRs
netlify.toml · netlify-build.sh · web/_redirects   ← deployment
```

## Golden rules (non-negotiable)

1. **Package boundaries.** A feature package never imports another feature
   package; shared things go to `vms_core`, `vms_design_system` or a data
   package like `vms_catalog`.
2. **Contract first.** API changes start in the backend repo's
   `contracts/openapi/vms-api.yaml` (use `/api-change`); then update the Dart
   models and repositories here.
3. **One design system.** UI uses only `vms_design_system` widgets and tokens,
   following `.agents/skills/vms-ui`. New component? Add it to the design
   system (and the skill) first.
4. **Errors:** branch on the API's problem `code`, never on message text.
5. **Tests travel with code.** Every behaviour change has a test in the same
   change. Don't weaken or delete a test to make it pass.
6. **No secrets in git.** The only setting is `VMS_API_BASE_URL` (not secret);
   `.env` is git-ignored.
7. **Stay in your lane.** Touch only the packages your task names. Changing
   `vms_core` or `vms_design_system` needs extra reviewers (CODEOWNERS).

## How to work (agent loop)

1. **Plan** — `/plan-feature` for anything bigger than a one-file fix.
2. **Build** — `/new-flutter-feature`, `/implement-screen`, `/api-change`.
3. **Verify** — `/verify` (analyzer, tests, and a browser check of the screen
   you changed); paste the evidence.
4. **Review** — `architecture-reviewer` and `contract-guardian` subagents.
5. **Ship** — `/pr-ready`.

## Definition of done

- [ ] `flutter analyze` is clean and every touched package's tests pass
- [ ] Models agree with the contract in the backend repo
- [ ] UI matches `vms-ui`, with loading, empty, error and no-results states
- [ ] Permissions respected (ADMIN / FLEET_MANAGER / VIEWER)
- [ ] Checked in Chrome against a running API

## Web-only target

- There are no `android/ios/macos/linux/windows` folders; don't add them.
- Don't use `dart:io` or mobile-only plugins; check a plugin supports web first.
- URLs are path-based (`usePathUrlStrategy()` in `lib/main.dart`); the server
  must fall back to `index.html` (`nginx.conf`).
- Hosting: **Netlify** (`netlify.toml` + `netlify-build.sh`; `web/_redirects`
  sends deep links to `index.html`). The API URL is baked in at build time:
  `--dart-define=VMS_API_BASE_URL=https://<api>/api` (Netlify env var).
- Container alternative: `Dockerfile` + `nginx.conf` (same-origin `/api/` proxy,
  build with `VMS_API_BASE_URL=/api`).

## Packages

| Package | Role | May depend on |
|---|---|---|
| `lib/` (`vms_app`) | composition root, router, app shell | everything |
| `vms_core` | config, `ApiClient`, `Result`, `ApiError`, `AuthSession`, `AppRoutes`, `FeatureModule`, `UiPreferences` | flutter, go_router, http |
| `vms_design_system` | tokens, theme, widgets (mirrors `.agents/skills/vms-ui`) | flutter, material_ui |
| `vms_catalog` | catalog data shared by features | vms_core |
| `feature_auth` | sign-in | core, design system |
| `feature_dashboard` | dashboard | core, design system |
| `feature_vehicles` | list, filters, register/edit, plate input | core, design system, catalog |
| `feature_settings` | catalogs, columns, dashboard cards | core, design system, catalog |

**Feature packages never import each other.** Navigate with `AppRoutes`; share
data through `vms_core` or a data package.

## Architecture inside a feature (MVVM, Flutter guidance)

```
lib/<feature>.dart       exports (public surface)
src/data/                models (fromJson/toJson match the OpenAPI contract) + repository
src/domain/              pure Dart rules (e.g. plate.dart)
src/ui/<screen>/         *_screen.dart (StatefulWidget) + *_view_model.dart (ChangeNotifier)
src/<feature>_feature.dart   FeatureModule: routes + sidebar items
```

- Repositories return `Result<T>` (`Ok`/`Err`), never throw for expected failures.
- Screens take a `createViewModel` factory; the State owns and disposes the VM.
- DI is explicit: `lib/main.dart` builds services and passes them to modules.
- Register a new feature by adding its module to the list in `lib/main.dart`
  and the package to the root `pubspec.yaml` (`workspace:` + `dependencies:`).

## Commands

```bash
flutter pub get
dart format . && flutter analyze
for p in . packages/*; do if [ -d "$p/test" ]; then (cd "$p" && flutter test) || exit 1; fi; done
flutter run -d chrome --web-port=5173 --dart-define=VMS_API_BASE_URL=http://localhost:8080/api   # or run-web.command
flutter build web --release --dart-define=VMS_API_BASE_URL=https://<api>/api                     # or build-web.command
```

The API must be running for anything beyond the sign-in screen: start it with
`run-backend.command` in the backend repo. Demo users: `admin@datavvy.com /
Admin@12345`, `manager@datavvy.com / Manager@12345`, `viewer@datavvy.com / Viewer@12345`.

The Dart team's skills in `.agents/skills/dart-*` and `flutter-*` (testing,
routing, layout fixes …) are installed from `dart-lang/skills` (`skills-lock.json`).
