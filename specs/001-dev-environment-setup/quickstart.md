# Quickstart: Validate Development Environment Setup

This guide defines the end-to-end checks to run after implementation. Command
semantics are specified in
[contracts/developer-commands.md](./contracts/developer-commands.md).

## Prerequisites

- Windows with WSL 2 and Ubuntu 22.04 or later.
- Docker Desktop using the WSL 2 backend with integration enabled for Ubuntu.
- Repository cloned inside the Linux filesystem, such as `~/projects/rv`.
- Java 25 and Node.js 24 LTS available inside WSL.

Do not install a second Docker Engine inside the WSL distribution.

## 1. Prepare a Clean Checkout

From the repository root inside WSL:

```bash
npm ci
npm run prepare
./scripts/dev/doctor.sh
```

Expected:

- Locked hook dependencies install successfully.
- Husky hooks become active.
- Every mandatory doctor check reports pass.
- The doctor exits non-zero with corrective guidance if Docker is stopped,
  Java is incompatible or the checkout is under `/mnt/`.

## 2. Verify the Build Contract

```bash
./gradlew --version
./gradlew clean check
```

Expected:

- The Wrapper reports Gradle 9.7.1 and JVM 25.
- Formatting, unit tests and build-logic functional tests pass.
- No globally installed Gradle command is required.
- Running `check` does not modify tracked files.

## 3. Validate Container Configuration

```bash
docker compose config
./scripts/dev/up.sh
./scripts/dev/status.sh
```

Expected:

- Compose resolves configuration without missing-variable errors.
- `up.sh` returns only after every required component is healthy.
- `status.sh` reports the smoke component as healthy.

Stop and restart:

```bash
./scripts/dev/down.sh
./scripts/dev/up.sh
```

Expected:

- Normal shutdown preserves named volumes.
- The subsequent startup succeeds and persistent test data remains available.

## 4. Validate Failure Reporting

Run each scenario independently and restore the original state afterward:

1. Stop Docker Desktop and run `doctor.sh`.
2. Occupy a configured host port and run `up.sh`.
3. Remove a required local variable and run `docker compose config`.
4. Force the smoke component health check to fail and run `up.sh`.

Expected for every scenario:

- The command exits non-zero.
- Output identifies the failed prerequisite or component.
- Output includes an actionable correction.
- No command reports a partial environment as healthy.

## 5. Validate Formatting Gate

Create and stage an intentionally misformatted supported file, then attempt a
commit:

```bash
git add <file>
git commit -m "test: verify formatting gate"
```

Expected:

- The commit is blocked.
- The output identifies the formatter and affected file.
- The hook does not modify the staged or unstaged content.

Correct formatting explicitly and retry:

```bash
./gradlew spotlessApply
git add <file>
git commit -m "test: verify formatting gate"
```

Expected: the formatting gate passes.

## 6. Validate Commit Message Policy

The complete grammar is in
[contracts/commit-policy.md](./contracts/commit-policy.md).

Try an invalid message:

```bash
git commit --allow-empty -m "updated files"
```

Expected: rejected with the violated rule and a valid example.

Try valid messages using each allowed type:

```bash
git commit --allow-empty -m "feat: validate feature commit"
git commit --allow-empty -m "fix: validate fix commit"
git commit --allow-empty -m "docs: validate docs commit"
git commit --allow-empty -m "refactor: validate refactor commit"
git commit --allow-empty -m "test: validate test commit"
git commit --allow-empty -m "build: validate build commit"
git commit --allow-empty -m "chore: validate chore commit"
```

Expected: every message passes policy validation.

## 7. Run the Full Verification

```bash
./scripts/quality/verify.sh
```

Expected:

- Build, formatting, tests, Compose validation and smoke scenarios pass.
- The command is non-interactive and suitable for future CI execution.
- Any failure preserves the underlying diagnostic and returns non-zero.

## 8. Validate Destructive Reset

```bash
./scripts/dev/reset.sh
```

Expected: cancellation preserves all volumes.

```bash
./scripts/dev/reset.sh --confirm
```

Expected: the environment stops and its named volumes are removed. A subsequent
`up.sh` creates a clean environment.
