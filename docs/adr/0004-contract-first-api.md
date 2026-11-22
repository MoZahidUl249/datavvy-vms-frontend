# ADR-0004: Contract-first REST API

**Status:** accepted · 2026-11-21

## Decision
`contracts/openapi/vms-api.yaml` in the backend repo is the source of truth between frontend and
backend teams. Changes land there first, reviewed by both leads; implementations
follow in the same PR. The server additionally publishes its generated spec
(`/v3/api-docs`) so drift is easy to spot.

Additive changes stay in `/api/v1`; breaking changes need `/api/v2` or an
agreed deprecation window.

## Next step
Generate a contract test (or Dart client) from the YAML in CI once the API
surface grows (see roadmap).
