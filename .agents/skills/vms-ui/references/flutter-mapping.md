# Design → Flutter mapping

How each `vms-ui` concept is implemented in `packages/vms_design_system`.
Import everything with `import 'package:vms_design_system/vms_design_system.dart';`.

| Design (SKILL.md) | Flutter |
|---|---|
| Tokens (`tokens.css`) | `VmsColors`, `VmsSpace`, `VmsRadius`, `VmsSize`, `VmsText`, `VmsShadows` |
| App shell (sidebar, sections Fleet / Workspace, user block) | `lib/app/shell/app_shell.dart`, items from each `FeatureModule.navItems` |
| Breadcrumb bar + page header + width cap | `VmsPage(crumbs:, title:, subtitle:, actions:, maxWidth:, body:)` |
| Card (hairline, no shadow) | `VmsCard(title:, trailing:, padding:, child:)` |
| Buttons primary / secondary / text / destructive | `VmsButton(variant: VmsButtonVariant.*, small:, loading:)` |
| Icon button with badge | `VmsIconButton(icon:, tooltip:, badgeCount:)` |
| Segmented control | `VmsSegmented<T>(segments: [VmsSegment(...)], selected:, onChanged:)` |
| Switch 51×31 | `VmsSwitch(value:, onChanged:)` |
| Status pill | `StatusPill(label:, tone: StatusTone.success / neutral / warning)` |
| Plate badge | `PlateBadge(number:, onTap:)` |
| Chips (filters, catalog values) | `VmsChip(label:, trailing:, onRemove:)` |
| Field with label above, "Optional", 18 px message line | `VmsTextField(label:, optional:, error:, helper:)`, `VmsSelect<T>`, `FieldLabel`, `FieldMessage`, `vmsInputDecoration()` |
| Date calendar (only dates with data) | `VmsDayPicker(enabledDays:, selected:, onChanged:)` |
| Skeletons | `Skeleton(width:, height:)` composed to match the final layout |
| Empty / no results | `EmptyState(icon:, title:, message:, actionLabel:, onAction:)` |
| Error banner / save summary | `ErrorBanner(message:, actionLabel:, children:)` |
| Toast (optional action) | `showVmsToast(context, message, actionLabel:, onAction:)` |
| Delete dialog | `showVmsConfirm(context, title:, message:, confirmLabel:)` |
| Keyboard hints | `KbdHint(keys:, label:)` |
| Segmented vehicle number | `feature_vehicles/lib/src/ui/form/plate_input.dart` (`PlateInput`) |
