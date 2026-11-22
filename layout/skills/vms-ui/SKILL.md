---
name: vms-ui
description: Design and build screens for the Datavvy VMS (Vehicle Management System) in its established visual language — deep-blue sidebar shell, white cards on soft gray, Apple-HIG-style UX. Use for any VMS screen, component, form, table, filter, dashboard or settings work, in design mockups or in frontend code.
---

# VMS UI — design language and UX rules

This skill records the decisions made across design versions V1–V8 of the VMS
(see the canvas "VMS — Vehicle Management System UI"). Follow it for every new
screen or component so the product stays one consistent system. V8 is the current
reference; anything not covered here should be solved the way V8 solves its
nearest neighbour.

## 1. Principles (Apple HIG, applied)

- **Clarity** — one large title per screen, one primary action per screen, status
  always as colour + word (never colour alone).
- **Deference** — white cards with a 1 px hairline, no shadows on cards. Only
  floating layers (dialogs, popovers, toasts) cast shadows.
- **Consistency** — every screen uses the same shell, header pattern, table,
  segmented control, status pill, field and button set. Add a new component to
  this skill before using it on a second screen.
- **Forgiveness** — destructive actions confirm first (Cancel beside Delete) and
  offer Undo in a toast. Errors say how to fix, with an example.
- **Feedback** — loading skeletons match final layout; buttons keep width while
  saving; saved rows flash light blue for ~2 s.

## 2. Tokens

Use `references/tokens.css` (CSS variables). Summary:

| Role | Value | Only for |
|---|---|---|
| Navigation | `#1F4E79` | sidebar, chart emphasis, selected tab/date |
| Primary action | `#5B9BD5` | the one main button, focus ring, accents |
| Accessible primary | `#2E75B6` | text links; primary fill if WCAG AA required |
| Page | `#F5F7FA` | background behind cards |
| Surface | `#FFFFFF` | cards, forms, tables, dialogs |
| Text | `#1F2937` | main text; `#4B5563` secondary; `#6B7280` meta |
| Success | `#16A34A` (pill bg `#DCFCE7`, text `#166534`) | Active status, saved, switch on |
| Destructive | `#DC2626` (bg `#FEF2F2`) | delete and errors — nothing else |
| Input border | `#D5DCE5` | inputs, selects, secondary buttons |
| Card border | `#E8ECF2` | cards |
| Divider | `#EEF2F6` | rows, section dividers |

Note: white text on `#5B9BD5` is 2.9:1 (fails AA). Keep it as brand default but
offer `#2E75B6` (4.8:1) when accessibility is required.

Type: `-apple-system, BlinkMacSystemFont, "Inter", "Segoe UI", sans-serif`.
Large title 28/34 bold (−0.02em) · section heading 17 semibold (card) or 15
semibold (form section) · body/controls 15 · table 14 · meta/helper 13 ·
labels 13 semibold `#374151` · table header 12 semibold `#6B7280`.
Use `font-variant-numeric: tabular-nums` for plates, counts, dates, money.

Space: 8 pt grid (4, 8, 12, 16, 24, 32). Radius: 6 plate badge · 8 small controls
· 10 buttons & inputs · 12 popover inner/plate group · 14 cards & popovers · 16
dialogs · 999 pills/chips.

Sizes: controls 44 px (page actions, inputs) or 36 px (toolbar, row actions,
icon buttons). Touch targets ≥ 44 px where tapped.

## 3. App shell

- Row: sidebar `flex: 1 1 240px` + content `flex: 999 1 560px; min-width: 0`,
  `flex-wrap: wrap` so the sidebar stacks on phones. Sidebar is never sticky.
- **Sidebar** (`#1F4E79`): brand block; `Dashboard`; section label **Fleet** →
  `Vehicles` (count badge), `Register vehicle`; section label **Workspace** →
  `Settings`; user block at bottom with Sign-out icon button. Items 44 px, radius
  10; selected = `rgba(255,255,255,.14)` pill + semibold white; hover `.08`.
  No coloured side-bars.
- **Breadcrumb bar**: 56 px, white, bottom border; `Vehicles › DHA-METRO-GA 11-4582`.
- **Page header**: large title + one-line subtitle left; actions right
  (secondary then primary).
- Content max-width 1180 (lists/dashboard), 880 (forms/settings).

## 4. Screens (current scope)

Screen map: Login → Dashboard → Vehicle List ↔ Register / Edit (+ Delete
dialog) · Settings. Sign-in lands on Dashboard. All screens reachable from the
sidebar; forms return to the list on Save, Cancel, breadcrumb or Esc.

- **Login** — centered 400 px card, email + password (Show/Hide), errors under
  fields, banner for wrong credentials, 44 px primary "Sign in".
- **Dashboard** — only data the app really has (vehicle records). KPI cards
  (Total, Active, Inactive, Needs details) open filtered list / record;
  Vehicles by type (bars), by fuel (stacked bar + legend), Recently updated (5,
  opens Edit), Needs details (missing chassis/year, "Add details"). Optional
  cards are switched on/off only in Settings (no Customize button on the
  Dashboard); empty and loading states.
- **Vehicle List** — see §5.
- **Register / Edit** — see §6. Edit pre-fills, "Save changes" disabled
  ("No changes") until something changes; Delete vehicle as red text bottom-left.
- **Settings** — settings-style sections: Vehicle types, Fuel types (chips with
  usage count, add via input + Enter, in-use values can't be removed, keep ≥1),
  Vehicle list columns, Dashboard cards (switches). Changes apply immediately.

## 5. Vehicle List

- Toolbar: status segmented control (All / Active / Inactive with counts) ·
  search · Sort select · **filter icon button** (badge = applied count) ·
  Columns icon button (→ Settings › Vehicle list columns).
- **Filter popover** (380 px, anchored under toolbar): Vehicle type, Fuel, Make,
  Last updated on, Added on. Choices are a *draft*: nothing changes until
  **Apply filters**. Footer shows live "N vehicles match", Reset, Apply. Esc / ×
  closes without applying. Applied filters appear as removable chips + "Clear all".
- **Date fields** open a small month calendar: only dates that have data are
  **bold, clickable**, with a blue dot; other days greyed and disabled; ‹ › jump
  to previous/next month that has data; selected day = navy fill; "Any date" clears.
- **Table**: first column = vehicle number as a **plate badge** (bordered,
  `#F8FAFC`, 14 bold, clickable → Edit). Configurable columns: Status, Type,
  Fuel, Make, Model, Year, Chassis no., Added, Last updated. Make/Model/Year that
  are *off* render as a 13 px secondary line under the plate
  (`Toyota Hiace · 2021`). Status pill sits right after the number. Rows 68 px.
  Actions column: labelled **Edit** (secondary 36 px) + **Delete** (red text,
  red tint on hover) — always visible.
- Sortable headers show ▲/▼ and `aria-sort`.
- States: skeleton rows matching columns; first-run empty ("Register your first
  vehicle" + what you'll need); no-results (repeat query/filters + exact way out).

## 6. Register / Edit form

- One card, sections separated by dividers, label column left (200 px) and
  fields right; sections: **Identification** (registration number, chassis),
  **Vehicle details** (type, make, model, year of manufacture), **Fuel & status**
  (fuel segmented radio, Active switch). Footer bar `#F8FAFC` with Cancel +
  primary; wraps on phones.
- Labels always above; "Optional" on optional fields instead of asterisks;
  18 px message line reserved under every field (no layout shift).
- **Registration number = segmented plate input**: Area (3 letters) · METRO
  toggle (auto-on for DHA, CTG, KHU, RAJ, SYL, BAR, RNG, MYM, GAZ, NAR, COM;
  user override wins) · Class (1–3 letters) · Series (2 digits) · Number
  (4 digits). Auto-advance when a part is full; a digit typed in Class moves to
  Series; Space/`-` advances; Backspace in empty part goes back and deletes; ←/→
  cross parts at edges; pasting a full number anywhere fills all parts;
  `inputmode="numeric"` on digit parts. Stored value: `DHA-METRO-GA 11-4582`.
- **Keyboard-only flow**: focus starts in Area (Edit: Make); Enter = next field
  (plate → chassis → type → make → model → year → fuel → active → save);
  arrows pick fuel (roving tabindex); Space toggles switch; Ctrl/⌘+Enter saves;
  Esc cancels. Show the shortcut hints under the title as `<kbd>` chips.
- **Validation**: show on blur or Save, clear as soon as fixed; duplicates show
  immediately. Messages: icon + red text + red border, say how to fix with an
  example ("Enter the model, like Hiace."). On Save, a summary at top lists each
  problem as a link to its field. Registration errors name the part ("Series
  needs 2 digits, like 11."). Chassis (optional): 6–17 letters/numbers.
- **Duplicate rule**: compare registration uppercased with spaces and hyphens
  removed; Edit ignores the vehicle being edited; offer "Open that vehicle";
  re-check on save (server 409 equivalent).

## 7. Shared components

Buttons (primary / secondary / text / destructive / icon) with hover, pressed
(`scale(.98)`), focus ring `3px rgba(91,155,213,.55)`, disabled, loading
(spinner, width kept). Segmented control (track `#EEF2F7`, selected white +
small shadow). Switch 51×31 (green on, `#CBD5E1` off). Status pill 24–26 px.
Chips 28–36 px pill. Toast: dark `#1F2937`, bottom-center, 6 s, Undo + dismiss.
Delete dialog: 400 px, title "Delete {number}?", body states consequence +
undo window, Cancel (secondary) + Delete (red).

## 8. Accessibility

Real `<button>`, `<a href>`, `<label for>`; `aria-label` on icon buttons;
`aria-invalid` + `aria-describedby` on fields; `aria-current` in nav;
`aria-pressed`/`aria-checked` for toggles; `role="alertdialog"` for delete;
`aria-live` for messages; respect `prefers-reduced-motion`. Text ≥ 4.5:1.

## 9. Data (mock until the API exists)

Vehicle: `id, registrationNo (unique, normalized), type, make, model, year,
fuel, chassisNo, active, createdAt, updatedAt`. Types and fuels come from
Settings. Do not add API calls in UI work unless asked; keep mock records in the
same shape the Spring Boot API will return.

## 10. Working on the design canvas

New rounds go on a new page (V9, V10 …); never overwrite an older version. Each
page gets a dated title note and a "what changed" sticky. Read the canvas files
before editing — the user edits by hand too.
