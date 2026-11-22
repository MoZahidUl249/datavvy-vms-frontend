# VMS — design canvas export

Exported 21 Nov 2026 from the Claude design canvas
**"VMS — Vehicle Management System UI"**
(https://claude.ai/artifact/APVKQAEG74tCDAu3hDd17N).

Every screen ever designed is kept, version by version. **V8 is the current design.**

## What's in this folder

| Path | What it is |
|---|---|
| `design-canvas/canvas.json` | Canvas layout: pages (V1–V8), frame positions, titles, notes |
| `design-canvas/*.dc.html` | One file per screen (frame). Self-contained markup + mock data + interaction logic |
| `../skills/vms-ui/` | The VMS design skill (rules, tokens) — see its SKILL.md |

The file names are kept exactly as on the canvas so `canvas.json` still points at them.

## Versions → files

| Version | Page | Files |
|---|---|---|
| V1 | Full VMS exploration | `Main` (Dashboard), `Vehicles`, `VehicleDetail`, `VehicleForm`, `Maintenance`, `Components` |
| V2 | Vehicle module (narrowed) | `ScreenMap`, `AppLogin`, `AppVehicleList`, `AppVehicleRegister`, `AppVehicleEdit` |
| V3 | V2 refined (components) | `V3Refinements`, `V3Login`, `V3VehicleList`, `V3VehicleRegister`, `V3VehicleEdit` |
| V4 | Reviewed & consistent | `V4Login`, `V4VehicleList`, `V4VehicleRegister`, `V4VehicleEdit` |
| V5 | V4 + Dashboard | `V5Login`, `V5Dashboard`, `V5VehicleList`, `V5VehicleRegister`, `V5VehicleEdit` |
| V6 | Easy registration number | `V6Login`, `V6Dashboard`, `V6VehicleList`, `V6VehicleRegister`, `V6VehicleEdit` |
| V7 | Filters, keyboard entry, Settings | `V7Login`, `V7Dashboard`, `V7VehicleList`, `V7VehicleRegister`, `V7VehicleEdit`, `V7Settings` |
| **V8** | **Filter panel, date calendars, list columns (current)** | `V8Login`, `V8Dashboard`, `V8VehicleList`, `V8Filters`, `V8VehicleRegister`, `V8VehicleEdit`, `V8Settings` |

From V2 on, the frames of one version are the **same prototype** started on a
different screen (the `start` setting at the bottom of each file). Change one and
copy it to the others, or treat `V8Login.dc.html` as the V8 source.

## Opening the files

These are design-canvas source files, not plain web pages: they need the canvas
runtime (`support.js`) to render, so double-clicking one in a browser shows raw
markup. To see and click them, use the canvas link above. To build the real app,
use them as the spec — markup, styles, mock data and behaviour are all inside —
together with `skills/vms-ui/SKILL.md`.

## Key behaviour in V8 (quick reference)

- Login → Dashboard; sidebar: Dashboard · Vehicles · Register vehicle · Settings.
- Vehicle List: filter button opens a panel (type, fuel, make, last-updated date,
  added date); nothing applies until **Apply filters**; date pickers only allow
  dates that have data; applied filters show as chips.
- Columns: every field can be a column (Settings › Vehicle list columns); make /
  model / year that are off show under the vehicle number.
- Register/Edit: segmented registration number (Area · Metro · Class · Series ·
  Number) with auto-advance and paste; keyboard-only flow (Enter next field,
  Ctrl/⌘+Enter save, Esc cancel); duplicate-number check.
- Settings: vehicle types, fuel types, list columns, dashboard cards.
- Mock data only — no API calls yet.
