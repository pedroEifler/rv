---

description: "Implementation tasks for the development environment setup"
---

# Tasks: Development Environment Setup

**Input**: Design documents from `/specs/001-dev-environment-setup/`

**Prerequisites**: plan.md, spec.md, research.md, data-model.md, contracts/,
quickstart.md

**Tests**: Required by the project constitution. Within each user story, create
the tests first, confirm that they fail for the expected reason, and only then
implement the behavior.

**Organization**: Tasks are grouped by user story so each story can be
implemented and validated as an independent increment.

## Format: `[ID] [P?] [Story] Description`

- **[P]**: Can run in parallel because it changes different files and does not
  depend on unfinished tasks in the same phase
- **[Story]**: Maps the task to a user story from spec.md
- Every task includes exact target paths

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Create the repository skeleton and version declarations needed by
all later work.

- [ ] T001 Create the planned directory skeleton with tracked placeholders in `build-logic/src/main/kotlin/.gitkeep`, `build-logic/src/test/kotlin/.gitkeep`, `infra/smoke/.gitkeep`, `scripts/dev/.gitkeep`, `scripts/quality/.gitkeep`, `services/.gitkeep`, `tests/environment/.gitkeep`, and `tests/hooks/.gitkeep`
- [ ] T002 [P] Define cross-platform line endings, executable-script handling, editor defaults, generated outputs, local `.env`, Node modules, Gradle state, and IDE files in `.gitattributes`, `.editorconfig`, and `.gitignore`
- [ ] T003 [P] Pin Node.js 24 LTS for contribution tooling in `.nvmrc`
- [ ] T004 [P] Create safe local configuration defaults and documented variable names without secrets in `.env.example`
- [ ] T005 Create the tooling manifest with exact Husky 9.1.7, lint-staged 17.5.1, commitlint 21.2.3, and Prettier 3.9.8 development dependencies and placeholder scripts in `package.json`
- [ ] T006 Generate and commit the deterministic npm dependency lock from `package.json` in `package-lock.json`

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Establish the versioned build and shared testing conventions that
block all user-story work.

**⚠️ CRITICAL**: No user story implementation begins until this phase is
complete.

- [ ] T007 Generate the Gradle 9.7.1 Wrapper with the binary distribution, URL validation, and distribution checksum in `gradlew`, `gradlew.bat`, `gradle/wrapper/gradle-wrapper.jar`, and `gradle/wrapper/gradle-wrapper.properties`
- [ ] T008 Define the `breaking-bad-production-simulator` root build, include `build-logic`, and include only existing service directories in `settings.gradle.kts`
- [ ] T009 [P] Pin Java toolchain `Exatamente 25`, Kotlin `Exatamente 2.4.20`, Spotless 8.10.2, and JUnit 6.1.3 aliases in `gradle/libs.versions.toml`
- [ ] T010 Configure root lifecycle aggregation for `build`, `test`, `check`, `spotlessCheck`, `spotlessApply`, and `clean` in `build.gradle.kts`
- [ ] T011 Configure the convention-plugin included build and Gradle TestKit dependencies in `build-logic/settings.gradle.kts` and `build-logic/build.gradle.kts`
- [ ] T012 [P] Create reusable shell assertions and temporary-workspace helpers in `tests/helpers/assertions.sh` and `tests/helpers/git-fixture.sh`
- [ ] T013 Verify the foundation with `./gradlew --version`, `./gradlew tasks`, and `npm ci`, recording any actionable setup caveats in `specs/001-dev-environment-setup/quickstart.md`

**Checkpoint**: The pinned build and test harness are available; user stories
can now proceed.

---

## Phase 3: User Story 1 - Start the Local Environment (Priority: P1) 🎯 MVP

**Goal**: A developer can diagnose prerequisites, start a healthy local
environment, inspect it, stop it without data loss, and reset it explicitly.

**Independent Test**: On a compatible clean WSL installation, run
`doctor.sh`, `up.sh`, `status.sh`, `down.sh`, restart, and `reset.sh`; verify
health, diagnostics, persistence across normal restarts, and explicit deletion
only on confirmed reset.

### Tests for User Story 1 ⚠️

> **NOTE: Write these tests first and confirm they fail before implementation.**

- [ ] T014 [P] [US1] Add doctor contract tests for `wslVersion` "Deve ser `2`", Ubuntu "22.04 ou posterior", Docker and Compose "Deve ser verdadeiro", Java "Deve corresponder ao Java 25", Node "Deve pertencer à linha Node 24 LTS", and repository path "Deve ser filesystem Linux, não `/mnt/*`" in `tests/environment/doctor-test.sh`
- [ ] T015 [P] [US1] Add Compose contract tests requiring a lowercase hyphenated service name, exactly one image/build origin, acyclic dependencies, mandatory long-running health checks, no versioned secret values, named persistent volumes, and at least one smoke component in `tests/environment/compose-contract-test.sh`
- [ ] T016 [P] [US1] Add lifecycle integration tests for `NOT_CONFIGURED`, `STOPPED`, `STARTING`, `HEALTHY`, `DEGRADED`, `FAILED`, `STOPPING`, and `RESETTING`, including timeout and occupied-port failures, in `tests/environment/lifecycle-test.sh`
- [ ] T017 [P] [US1] Add persistence tests proving `down.sh` preserves named volumes, cancelled reset preserves data, and only `reset.sh --confirm` removes data in `tests/environment/persistence-test.sh`

### Implementation for User Story 1

- [ ] T018 [P] [US1] Create the minimal persistent smoke component and health endpoint assets in `infra/smoke/Dockerfile`, `infra/smoke/server.sh`, and `infra/smoke/healthcheck.sh`
- [ ] T019 [US1] Define the fixed Compose project name, smoke component, required configuration, named volume, health check, and readiness dependency semantics in `compose.yaml`
- [ ] T020 [US1] Implement exhaustive prerequisite checks with pass/warning/failure output and corrective actions in `scripts/dev/doctor.sh`
- [ ] T021 [US1] Implement configuration validation, occupied-port detection, Compose startup, health polling, timeout failure, and non-zero partial-start handling in `scripts/dev/up.sh`
- [ ] T022 [P] [US1] Implement stable stopped, starting, healthy, unhealthy, and exited state reporting in `scripts/dev/status.sh`
- [ ] T023 [P] [US1] Implement idempotent shutdown that removes containers and networks but preserves named volumes in `scripts/dev/down.sh`
- [ ] T024 [US1] Implement interactive cancellation and exact `--confirm` non-interactive volume deletion in `scripts/dev/reset.sh`
- [ ] T025 [US1] Execute all tests in `tests/environment/` and the environment sections of `specs/001-dev-environment-setup/quickstart.md`, then fix lifecycle behavior until the story passes independently

**Checkpoint**: User Story 1 is a usable MVP for local environment lifecycle.

---

## Phase 4: User Story 2 - Build Projects Consistently (Priority: P2)

**Goal**: A developer can build, test, format-check, format, and clean all JVM
projects through the committed Wrapper with identical versions and results.

**Independent Test**: In a clean checkout with no global Gradle installation,
run the documented Wrapper commands, inject a formatting violation to observe a
non-mutating failure, correct it explicitly, and obtain a successful build.

### Tests for User Story 2 ⚠️

> **NOTE: Write these tests first and confirm they fail before implementation.**

- [ ] T026 [P] [US2] Add Gradle TestKit tests proving Java toolchain `Exatamente 25`, Kotlin `Exatamente 2.4.20`, and mandatory build, test, and quality-check tasks in `build-logic/src/test/kotlin/BuildConventionsFunctionalTest.kt`
- [ ] T027 [P] [US2] Add Gradle TestKit tests proving format check and apply are separate, `spotlessCheck` does not mutate fixtures, and Java, Kotlin, Kotlin Gradle, Markdown, JSON, and YAML are covered in `build-logic/src/test/kotlin/FormattingConventionsFunctionalTest.kt`
- [ ] T028 [P] [US2] Add shell integration tests proving the Wrapper works without global Gradle, returns non-zero on violations, and produces repeatable clean-check results in `tests/environment/build-interface-test.sh`

### Implementation for User Story 2

- [ ] T029 [US2] Implement the neutral JVM base convention with Java 25 toolchain, repositories, JUnit Platform, test logging, and no shared domain dependencies in `build-logic/src/main/kotlin/simulator.jvm-base.gradle.kts`
- [ ] T030 [P] [US2] Implement the Java service convention in `build-logic/src/main/kotlin/simulator.java-service.gradle.kts`
- [ ] T031 [P] [US2] Implement the Kotlin service convention using Kotlin 2.4.20 in `build-logic/src/main/kotlin/simulator.kotlin-service.gradle.kts`
- [ ] T032 [US2] Implement Spotless check/apply conventions for Java, Kotlin, Gradle Kotlin DSL, Markdown, JSON, and YAML in `build-logic/src/main/kotlin/simulator.formatting.gradle.kts`
- [ ] T033 [US2] Register convention plugin IDs and align TestKit fixtures with the plugin classpath in `build-logic/build.gradle.kts`
- [ ] T034 [US2] Implement the non-interactive aggregate build and formatting verification sequence with preserved diagnostics in `scripts/quality/verify.sh`
- [ ] T035 [US2] Execute `tests/environment/build-interface-test.sh`, the build-logic TestKit suite, and the build sections of `specs/001-dev-environment-setup/quickstart.md`, then fix reproducibility and mutation issues until the story passes independently

**Checkpoint**: User Stories 1 and 2 work independently; future services can
adopt either Java or Kotlin conventions.

---

## Phase 5: User Story 3 - Prevent Invalid Commits (Priority: P3)

**Goal**: Contributors receive fast, actionable rejection of staged quality
violations and invalid Conventional Commit messages without hooks changing
their staged or unstaged content.

**Independent Test**: In an isolated Git fixture, attempt commits with
misformatted staged files, partial staging, tool failures, invalid messages,
and valid examples of every permitted type; confirm only compliant commits are
created and file contents remain unchanged by hooks.

### Tests for User Story 3 ⚠️

> **NOTE: Write these tests first and confirm they fail before implementation.**

- [ ] T036 [P] [US3] Add commit-message tests for mandatory allowed type, optional lowercase no-whitespace scope, optional `!`, required colon-space separator, non-empty description, no trailing period, configured header limit, and Git trailer compatibility in `tests/hooks/commit-msg-test.sh`
- [ ] T037 [P] [US3] Add pre-commit tests requiring unique readable gates, `pre-commit` stage-derived scope, non-interactive commands, meaningful non-zero exits, mandatory correction messages, and `mutatesFiles` "Deve ser falso nos hooks" in `tests/hooks/pre-commit-test.sh`
- [ ] T038 [P] [US3] Add partial-stage and no-applicable-files regression tests proving unstaged content is preserved and empty relevant scopes pass cleanly in `tests/hooks/staged-content-test.sh`
- [ ] T039 [P] [US3] Add tool-failure tests proving missing or crashed validators fail distinctly rather than returning success in `tests/hooks/tool-failure-test.sh`

### Implementation for User Story 3

- [ ] T040 [P] [US3] Configure Conventional Commit types, scope casing, whitespace, description, period, header-length, breaking marker, and explicit exemption patterns in `commitlint.config.mjs`
- [ ] T041 [P] [US3] Configure staged Markdown, JSON, and YAML checks with Prettier `--check` and route JVM/build files to the non-mutating Gradle checks in `lint-staged.config.mjs`
- [ ] T042 [US3] Implement staged-file classification, no-applicable-files success, preserved diagnostics, and non-mutating Gradle verification in `scripts/quality/check-staged.sh`
- [ ] T043 [US3] Replace placeholder package scripts with exact `prepare`, `format:check`, staged validation, commitlint, and full verification commands in `package.json`, then refresh `package-lock.json`
- [ ] T044 [P] [US3] Install the pre-commit entry point that delegates to the staged quality contract in `.husky/pre-commit`
- [ ] T045 [P] [US3] Install the commit-msg entry point that passes the exact Git message-file argument to commitlint in `.husky/commit-msg`
- [ ] T046 [US3] Execute all isolated tests in `tests/hooks/` and the hook sections of `specs/001-dev-environment-setup/quickstart.md`, then fix mutation, error-reporting, and policy behavior until the story passes independently

**Checkpoint**: All three user stories are independently functional and
verified.

---

## Phase 6: Polish & Cross-Cutting Concerns

**Purpose**: Complete documentation, safety checks, and clean-checkout
verification across the feature.

- [ ] T047 [P] Document WSL 2 and Docker Desktop prerequisites, Linux-filesystem checkout, initial setup, everyday commands, troubleshooting, and controlled version upgrades in `README.md`
- [ ] T048 [P] Add concise usage comments and actionable failure text to all public scripts in `scripts/dev/` and `scripts/quality/`
- [ ] T049 Verify no secret or local `.env` value is tracked and document safe configuration handling in `.env.example` and `.gitignore`
- [ ] T050 Run `./scripts/quality/verify.sh` from a clean checkout and complete every scenario in `specs/001-dev-environment-setup/quickstart.md`
- [ ] T051 Measure doctor, pre-commit, and cached startup durations against the plan targets and record reproducible evidence in `specs/001-dev-environment-setup/checklists/requirements.md`
- [ ] T052 Review the delivered files against every functional requirement and constitutional gate, recording final compliance notes in `specs/001-dev-environment-setup/checklists/requirements.md`

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies; begins immediately.
- **Foundational (Phase 2)**: Depends on Phase 1 and blocks all user stories.
- **User Story 1 (Phase 3)**: Depends only on Phase 2.
- **User Story 2 (Phase 4)**: Depends only on Phase 2. It can run in parallel
  with User Story 1, though the recommended single-developer order is P1 then
  P2.
- **User Story 3 (Phase 5)**: Depends on Phase 2 for package and Wrapper
  foundations. Its final verification uses quality commands from User Story 2,
  so T042-T046 depend on T032 and T034.
- **Polish (Phase 6)**: Depends on all selected user stories.

### User Story Dependency Graph

```text
Setup -> Foundational -> US1
                     \-> US2 -> US3 final integration
                     \-> US3 tests/configuration

US1 + US2 + US3 -> Polish
```

### Within Each User Story

- Write tests first and confirm failure for the intended missing behavior.
- Implement lower-level configuration or component definitions before lifecycle
  scripts and aggregate commands.
- Preserve contract names and exit semantics from `contracts/`.
- Complete the independent test before proceeding to the next priority.

### Parallel Opportunities

- T002-T004 can run concurrently after T001.
- T009 and T012 can run concurrently after the Wrapper/build skeleton exists.
- T014-T017 can be authored concurrently before User Story 1 implementation.
- T022 and T023 can run concurrently after the Compose contract is fixed.
- T026-T028 can be authored concurrently before User Story 2 implementation.
- T030 and T031 can run concurrently after T029.
- T036-T039 can be authored concurrently before User Story 3 implementation.
- T040 and T041 can run concurrently; T044 and T045 can run concurrently after
  their configurations exist.
- T047 and T048 can run concurrently in the polish phase.

---

## Parallel Example: User Story 1

```text
Task T014: Write tests/environment/doctor-test.sh
Task T015: Write tests/environment/compose-contract-test.sh
Task T016: Write tests/environment/lifecycle-test.sh
Task T017: Write tests/environment/persistence-test.sh
```

## Parallel Example: User Story 2

```text
Task T026: Write build-logic/src/test/kotlin/BuildConventionsFunctionalTest.kt
Task T027: Write build-logic/src/test/kotlin/FormattingConventionsFunctionalTest.kt
Task T028: Write tests/environment/build-interface-test.sh
```

## Parallel Example: User Story 3

```text
Task T036: Write tests/hooks/commit-msg-test.sh
Task T037: Write tests/hooks/pre-commit-test.sh
Task T038: Write tests/hooks/staged-content-test.sh
Task T039: Write tests/hooks/tool-failure-test.sh
```

---

## Implementation Strategy

### MVP First (User Story 1 Only)

1. Complete Setup.
2. Complete Foundational.
3. Write and fail the User Story 1 tests.
4. Implement doctor, Compose smoke component, lifecycle and persistence.
5. Stop and validate User Story 1 independently.

The MVP gives every contributor a reproducible, diagnosable local environment
before build conventions and commit enforcement are added.

### Incremental Delivery

1. **Foundation**: Version declarations, repository hygiene, Wrapper and test
   harness.
2. **US1**: Reproducible local lifecycle and health.
3. **US2**: Reproducible JVM build and quality interface.
4. **US3**: Non-destructive staged checks and commit-message enforcement.
5. **Polish**: Full clean-checkout validation and documentation.

### Parallel Team Strategy

After Foundational:

- Developer A implements User Story 1.
- Developer B implements User Story 2.
- Developer C writes User Story 3 tests and commitlint/lint-staged
  configuration, then integrates with the completed quality commands from
  User Story 2.

---

## Notes

- `[P]` means different files and no dependency on another unfinished task in
  the same phase.
- User-story labels provide traceability to `spec.md`.
- Tests precede implementation in every user-story phase.
- Hooks MUST check only staged scope and MUST NOT run automatic formatters.
- `down.sh` preserves volumes; only confirmed `reset.sh` removes them.
- Commit after each task or coherent task group using the policy in
  `contracts/commit-policy.md`.
