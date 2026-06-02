---
name: commit
description: >
  Create git commit messages in the project's conventional commit format.
  Load when committing code, writing a commit message, or staging changes.
  Triggers: git commit, commit message, stage changes, make a commit.
license: MIT
compatibility: opencode
---

# Git Commit

Use this skill when creating a git commit.

## Commit Message Format

```
<prefix>(<scope>): <what was done>
```

### Prefixes

| Prefix     | When to Use                                      |
|------------|--------------------------------------------------|
| `feat`     | New feature                                      |
| `fix`      | Bug fix                                          |
| `refactor` | Code restructuring without behavior change       |
| `docs`     | Documentation only                               |
| `chore`    | Dependency updates, build config, tooling, etc.  |

### Scope

- **If a Jira ticket number is available** (from the branch name or explicitly told by the user): use it as the scope.
  - Branch `feature/PROJ-123-add-login` → scope is `PROJ-123`
  - Example: `feat(PROJ-123): add login endpoint`
- **If no ticket number is available**: use the component or library that was modified as the scope.
  - Example: `fix(auth): handle expired token edge case`

### Message Body

- Lowercase, imperative mood ("add", "fix", "remove", not "added", "fixes")
- No period at the end
- Keep it short and descriptive — one line is the goal

## Pre-Commit: Run Tests

**ALWAYS run tests before committing.** Load and follow the `go-test` skill.

Run tests with all tags:

```bash
go test -tags=integration,component,e2e ./...
```

Do NOT commit if tests are failing.

## Examples

```
feat(PROJ-42): add user registration endpoint
fix(PROJ-99): prevent nil pointer in order processor
refactor(payment): extract charge logic into service
docs(README): update local setup instructions
chore(deps): bump go-redis to v9.1.0
fix(auth): handle expired token edge case
```
