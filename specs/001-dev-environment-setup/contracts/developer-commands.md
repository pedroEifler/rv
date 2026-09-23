# Contract: Developer Commands

Estes comandos constituem a interface pública do ambiente local. A
implementação pode delegar internamente, mas nomes, resultados e códigos de
saída devem permanecer estáveis.

## Environment Doctor

```bash
./scripts/dev/doctor.sh
```

Validates WSL version, Linux filesystem location, Docker connectivity, Compose,
Java and Node versions.

- Exit `0`: all mandatory prerequisites pass.
- Non-zero: one or more checks fail.
- Output must list every check as pass, warning or failure and include a
  corrective action for each failure.

## Start Environment

```bash
./scripts/dev/up.sh
```

Validates configuration, starts required components and waits for health.

- Exit `0`: every required component is healthy.
- Non-zero: configuration is invalid, startup fails or readiness times out.
- Must not remove existing named volumes.

## Show Status

```bash
./scripts/dev/status.sh
```

Shows each component as stopped, starting, healthy, unhealthy or exited.

- Exit `0`: state was obtained successfully.
- Non-zero: the runtime cannot be queried.

## Stop Environment

```bash
./scripts/dev/down.sh
```

Stops and removes runtime containers and networks while preserving named
volumes.

- Exit `0`: environment is stopped or was already stopped.
- Non-zero: shutdown is incomplete.

## Reset Environment

Interactive:

```bash
./scripts/dev/reset.sh
```

Non-interactive:

```bash
./scripts/dev/reset.sh --confirm
```

Stops the environment and removes its named volumes.

- Interactive execution must require explicit confirmation.
- Non-interactive execution must require the exact `--confirm` flag.
- Cancellation exits without deleting data.

## Full Verification

```bash
./scripts/quality/verify.sh
```

Runs formatting checks, static quality checks, unit tests, build-logic
functional tests, Compose configuration validation and environment smoke tests.

- Exit `0`: all mandatory checks pass.
- Non-zero: at least one check fails.
- Output must identify the failing check and preserve its diagnostic output.

## Build Interface

```bash
./gradlew build
./gradlew test
./gradlew check
./gradlew spotlessCheck
./gradlew spotlessApply
./gradlew clean
```

- All commands use the committed Wrapper.
- Check commands must not modify source files.
- `spotlessApply` is the only standard command above allowed to change
  formatting.
- Commands must support non-interactive execution.

## Hook Tooling Interface

```bash
npm ci
npm run prepare
npm run format:check
npm run commitlint -- --edit <message-file>
```

- `npm ci` installs exactly the locked tooling versions.
- `prepare` installs the repository hooks.
- `format:check` reports formatting violations without changing files.
- `commitlint` returns non-zero for a message outside the commit policy.
