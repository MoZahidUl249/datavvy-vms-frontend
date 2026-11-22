---
trigger: glob
globs: "packages/**/data/*.dart"
description: "The OpenAPI contract is the source of truth; keep both sides in sync."
---

# API contract rules

- `contracts/openapi/vms-api.yaml` in the backend repo is the source of truth. Change it first, in
  the same PR as both implementations, and run `/api-change`.
- Additive changes only within `/api/v1` (new optional fields, new endpoints).
  Removing/renaming a field or changing its type = breaking → needs `/api/v2`
  or a deprecation period agreed by both leads.
- Field names are camelCase and identical in YAML, Java records and Dart models.
- Every error response is a problem document with `code`; document new codes in
  the contract's response descriptions.
- After changing the backend, compare with the live spec at
  `http://localhost:8080/v3/api-docs`.
