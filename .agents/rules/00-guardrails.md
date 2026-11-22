---
trigger: always_on
description: "Safety and scope guardrails for every task in the VMS repo."
---

# Guardrails

- Work only inside the modules the task names. Changing `vms-platform`,
  `vms_core`, `vms_design_system`, `contracts/` or `.agents/` needs to be called
  out in the plan before you edit.
- Never edit an existing Flyway migration, never drop or rename a column in
  place — use expand/contract (see `/db-migration`).
- Never commit secrets, tokens, real customer data or `.env` files.
- Never weaken, skip or delete a test to get green; fix the code or explain.
- Never bypass security: every new endpoint has `@PreAuthorize`.
- Don't add a dependency without saying why in the plan (licence, size, owner).
- Don't touch `layout/` (design source) — read it, implement from it.
- Ask before destructive commands (`rm -rf`, `git reset --hard`, dropping DBs).
- Finish every task with evidence: commands run and their result.
