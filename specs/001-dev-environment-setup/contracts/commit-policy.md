# Contract: Commit Policy

## Header Grammar

```text
<type>(<optional-scope>)<optional-breaking-marker>: <description>
```

Examples:

```text
feat(stock): add inventory reservation
fix(delivery): handle unavailable route
docs: explain local setup
refactor(quality)!: replace inspection contract
test(mixing): cover concurrent batches
build: upgrade Gradle wrapper
chore: update repository metadata
```

## Allowed Types

| Type | Intended use |
|------|--------------|
| `feat` | New user-visible or domain capability |
| `fix` | Defect correction |
| `docs` | Documentation-only change |
| `refactor` | Internal restructuring without behavior change |
| `test` | Test additions or corrections |
| `build` | Build system or dependency change |
| `chore` | Repository maintenance not covered above |

## Validation Rules

- Type is mandatory and must be one of the allowed types.
- Scope is optional, lowercase and contains no whitespace.
- `!` is optional and denotes a breaking change.
- A colon and one space must separate prefix and description.
- Description is mandatory, must not end with a period and must fit within the
  configured header length.
- Merge, revert and automated dependency commits may be exempt only through
  explicit patterns committed in the policy configuration.
- A rejected message must show the violated rule and at least one valid example.

## Hook Behavior

`commit-msg` receives the Git message file path and validates its content.

- Valid message: exit `0`.
- Invalid message: non-zero exit and no commit created.
- Tool execution failure: non-zero exit with a distinct diagnostic; it must not
  be reported as a valid commit.
