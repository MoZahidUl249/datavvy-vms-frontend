---
name: api-change
description: End-to-end procedure for adding or changing a REST field or endpoint — OpenAPI contract first, then migration, backend DTO/entity/service, Flutter model/repository/UI, and tests on both sides. Use whenever a request or response shape changes, or when the user types /api-change.
---

# Change the API (contract-first)

Worked example: add optional **`colour`** to vehicles.

1. **Contract** — `contracts/openapi/vms-api.yaml` in the backend repo
   - Add `colour: { type: string, nullable: true, maxLength: 30 }` to
     `VehicleRequest` and `Vehicle` (next to vehicleNumber, company, type, brand, model, status).
   - Additive + optional ⇒ non-breaking. Renames/removals ⇒ stop and raise it
     with both leads (needs `/api/v2` or deprecation).
2. **Migration** (`/db-migration`) —
   `V2026.12.01.0930__vehicle_add_colour.sql`: `ALTER TABLE vehicle ADD COLUMN colour VARCHAR(30) NULL;`
3. **Backend** (`vms-vehicle`)
   - `api/VehicleRequest` + `@Size(max = 30, message = "Keep the colour under 30 characters.")`
   - `api/VehicleResponse`, `domain/Vehicle` field + `VehicleDetails`,
     `application/VehicleService.validate` + `VehicleMapper`.
   - Test: extend `VehicleApiIntegrationTest` (create with colour, read it back).
   - Document it in `API.md` in the backend repo (schema table + examples).
4. **Frontend** (`feature_vehicles`)
   - `Vehicle.fromJson`, `VehicleDraft.toJson`.
   - `VehicleField` + form view model setter/validation; form screen field;
     optional table column → add to `VehicleColumn` in `vms_core` (platform review).
   - Test: view model / model parsing test.
5. **Compare** running spec `http://localhost:8080/v3/api-docs` with the YAML.
6. **Verify** with `/verify`, then `/pr-ready`. The PR needs both backend and
   frontend lead approval because it touches `contracts/`.
