---
trigger: model_decision
description: "Use when writing, fixing or reviewing tests in backend or frontend."
---

# Testing rules

- Backend domain logic → plain JUnit 5 + AssertJ in the module.
- Backend HTTP behaviour (status codes, problem `code`, security) →
  `vms-app/src/test/.../VmsApiIntegrationTest` style: `@SpringBootTest`,
  `@AutoConfigureMockMvc`, `@ActiveProfiles("test")`, `@Transactional`.
- Architecture rules live in `ArchitectureTest`; extend it when adding a module.
- Flutter view models → unit tests with a fake repository (see
  `feature_auth/test/login_view_model_test.dart`).
- Pure Dart rules (plate parsing, filters) → plain `test()`.
- Name tests after behaviour ("viewer cannot change fleet"), one behaviour each.
- A bug fix starts with a failing test that reproduces it.
