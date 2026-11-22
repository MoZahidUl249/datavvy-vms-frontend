---
name: pr-ready
description: Prepares a change for review — small focused diff, self-review against the Definition of Done, reviewer subagents, and a PR description from the repo template. Use when work is finished and verified, or when the user types /pr-ready.
---

# Make it PR-ready

1. **Scope** — `git diff --stat main...`. Unrelated changes go to another branch.
   Aim for < 400 changed lines; split by module if larger.
2. **Self-review** against the Definition of Done in `AGENTS.md`.
3. **Reviewers** — ask the subagents and fix their findings:
   - `architecture-reviewer` (boundaries, layering, migrations)
   - `contract-guardian` (YAML ⇄ Java ⇄ Dart)
   - `qa-verifier` (tests and states coverage)
4. **Verify** — `/verify` evidence must be fresh (after the last change).
5. **Commit** — Conventional Commits with the module as scope:
   `feat(vehicle): add colour`, `fix(feature_vehicles): keep filter chips after save`.
6. **PR description** — fill `.github/pull_request_template.md`: what & why,
   modules touched, checklist, screenshots, API examples. Mention which
   CODEOWNERS teams must approve.
