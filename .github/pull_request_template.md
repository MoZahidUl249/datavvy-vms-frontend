## What & why
<!-- One paragraph. Link the issue. -->

## Modules touched
- [ ] backend: <!-- vms-vehicle, ... -->
- [ ] frontend: <!-- feature_vehicles, ... -->
- [ ] contract (`contracts/openapi/vms-api.yaml` in the backend repo) — if yes, both leads review

## Checklist (Definition of Done — see AGENTS.md)
- [ ] `mvn -f backend verify` passes (includes ArchitectureTest)
- [ ] `cd frontend && flutter analyze && flutter test` passes
- [ ] New/changed behaviour has tests
- [ ] Schema change is a new timestamped Flyway file (no edits to applied ones)
- [ ] UI follows `.agents/skills/vms-ui` (screenshots below)
- [ ] No secrets, no TODOs without an issue link

## Screenshots / API examples
