---
name: implement-screen
description: Implements or updates a Flutter screen from the V8 design canvas files in layout/design-canvas using the vms_design_system widgets, MVVM view model and all UI states, then checks it in the browser. Use when building UI from the design, or when the user types /implement-screen.
---

# Implement a screen from the design

1. **Read the spec**
   - `.agents/skills/vms-ui/SKILL.md` (rules, tokens, components)
   - `.agents/skills/vms-ui/references/flutter-mapping.md` (design → widget)
   - The frame: `layout/design-canvas/V8<Screen>.dc.html`. It is canvas source:
     markup + mock data + behaviour in one file. Search it for the screen's
     section, the `MOCK_` data and handlers (`onClick`, `onKeyDown`) to learn
     behaviour. Do not try to run it.
2. **Map** every element to an existing design-system widget. If something is
   missing, add it to `packages/vms_design_system` and document it in
   the skill **before** using it.
3. **Build** in the owning feature package:
   - view model: state + commands, talks to the repository (`Result<T>`)
   - screen: `VmsPage` + widgets; no business logic in widgets
   - states: loading skeleton matching layout, first-run empty, no results,
     error with retry, permission-limited (VIEWER) variant
   - keyboard: Enter/Esc/shortcuts as the design specifies; tooltips on icon buttons
4. **Wire** the route in the feature's `FeatureModule` (and `AppRoutes` if shared).
5. **Check in the browser** (Antigravity browser agent):
   - `flutter run -d chrome --dart-define=VMS_API_BASE_URL=http://localhost:8080/api`
   - sign in as admin and as viewer; compare with the V8 frame side by side;
     try the keyboard flow; resize to phone width (sidebar becomes a drawer).
   - capture screenshots for the walkthrough.
6. **Test** the view model; run `/verify`.
