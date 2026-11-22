---
name: plan-feature
description: Turns a feature request into a module-by-module implementation plan (contract, migrations, backend, frontend, tests, owners) before any code is written. Use for anything larger than a one-file fix, or when the user types /plan-feature.
---

# Plan a feature

Produce a **plan artifact** and stop for approval when the plan touches more
than one module or any shared area (contract, `vms-platform`, `vms_core`,
`vms_design_system`).

## Steps

1. **Restate** the goal in one paragraph and list acceptance criteria as
   testable bullets ("A viewer sees no Delete button").
2. **Locate** the work. Read `AGENTS.md`, `docs/architecture.md` (backend repo),
   `docs/team-ownership.md` (backend repo). For UI, find the V8 frame in
   `layout/design-canvas/` and read `.agents/skills/vms-ui/SKILL.md`.
3. **Decide placement**:
   - New bounded context (own table, own rules, own team)? → new backend module
     + new Flutter feature package (`/new-backend-module`, `/new-flutter-feature`).
   - Extends an existing aggregate? → that module only.
   - Cross-module read? → consume the other module's `api`; if it lacks what
     you need, add to its `api` (owner review) — never reach into internals.
4. **Fill this table** in the plan:

   | Area | Change | Files / module | Owner (CODEOWNERS) |
   |---|---|---|---|
   | Contract | | `contracts/openapi/vms-api.yaml` in the backend repo | backend + frontend leads |
   | Migration | | backend repo: `<module>/…/db/migration/<module>/` | |
   | Backend | | | |
   | Frontend | | | |
   | Tests | | | |
   | Docs | | | |

5. **Risks & decisions**: breaking API? data backfill? permissions? performance
   (indexes, paging)? Write an ADR in `docs/adr/` for any lasting decision.
6. **Parallelisation**: split into tasks one agent can own (one module each).
   Order: contract → migration → backend → frontend → verification.
7. **Verification plan**: which tests, which `/verify` checks, which screens to
   open in the browser.

Keep the plan short enough to review in two minutes.
