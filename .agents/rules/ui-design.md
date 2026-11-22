---
trigger: glob
globs: "packages/**/ui/**/*.dart, packages/vms_design_system/**/*.dart, lib/app/**/*.dart"
description: "UI must follow the vms-ui design language (V8)."
---

# UI rules

- Read `.agents/skills/vms-ui/SKILL.md` before building or changing a screen.
  V8 frames in `layout/design-canvas/V8*.dc.html` are the reference.
- Build from `vms_design_system` widgets: `VmsPage`, `VmsCard`, `VmsButton`,
  `VmsTextField`, `VmsSelect`, `VmsSegmented`, `VmsSwitch`, `StatusPill`,
  `PlateBadge`, `VmsChip`, `EmptyState`, `ErrorBanner`, `showVmsToast`, `showVmsConfirm`.
- Colours/spacing/radius only from `VmsColors`, `VmsSpace`, `VmsRadius`, `VmsText`.
- One primary action per screen; destructive actions confirm first.
- Every screen handles loading (skeleton), empty, error and no-results states.
- Status = colour + word. Icon-only buttons have a tooltip. Fields have labels.
- Need a new component? Add it to `vms_design_system` and document it in the skill first.
