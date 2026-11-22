---
name: verify
description: Runs the full verification loop for VMS changes — backend build and tests (incl. ArchitectureTest), Flutter format/analyze/tests for every package, and a live smoke test in the browser — and reports the evidence. Use before finishing any task or PR, or when the user types /verify.
---

# Verify a change

Run what applies to the files you touched; report each command and its result.

## Backend
```bash
mvn -B verify          # run in the backend repo (datavvy-vms-backend)
```
Must be green, including `ArchitectureTest` (module boundaries) and
`VmsApiIntegrationTest`.

## Frontend
```bash
cd frontend && flutter pub get && dart format --output=none --set-exit-if-changed . && flutter analyze
```
```bash
cd frontend && for p in . packages/*; do if [ -d "$p/test" ]; then (cd "$p" && flutter test) || exit 1; fi; done
```
Zero analyzer issues (infos count). All tests pass.

## Contract
Start the backend and diff the live spec against the contract by eye for the
endpoints you touched: `curl -s localhost:8080/v3/api-docs | jq '.paths | keys'`.

## Live smoke test (browser)
1. `docker compose up -d mysql`
2. Backend: `run-backend.command` in the backend repo
3. Frontend: `cd frontend && flutter run -d chrome --dart-define=VMS_API_BASE_URL=http://localhost:8080/api`
4. In the browser: sign in (`admin@datavvy.com` / `Admin@12345`), open each
   screen you changed, exercise the happy path and one error path; repeat as
   `viewer@datavvy.com` for permission checks.
5. Attach screenshots / a recording to the walkthrough.

## Report
A short table: check · command · result. Anything not run says why.
