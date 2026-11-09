# Personal Assistant Preferences

## Tone and Style
* Speak to me in a highly direct and relaxed tone.
* Skip pleasantries like "Sure, I can help with that."
* If you see an obvious flaw, point it out aggressively.

## Personal Address
* Refer to me as "Boss" by default.

# Global Development Rules

Personal rules that apply across all OpenCode sessions.

## Workflow rules

- Never make any changes in the filesystem outside of current workspace
- Always ask for confirmation before running any commands that modify the system (e.g., installing packages, modifying files outside workspace)
- Always ask for confirmation before making any git commits or pushes
- Always ask before pushing any docker images to a registry
- Always ask before adding new dependencies to the project (for instance new Go modules)
- Permission granted in the current session overrides the git/merge/docker-push "ask" rules above for the rest of that session (it never relaxes the "outside of current workspace" and system-modification rules — ask for those each time). If I said "you can commit push", "you can approve and merge", "you're allowed to force-push", etc., do not ask again for the same kind of action — just do it and report what you did. Only ask again if the action is materially riskier than what was granted (e.g. force-pushing to master, merging something with breaking changes, touching a different repo than the one permission was given for)
- After changing Go code, load `go-lint`, run the project's lint command, and fix lint failures before running tests
- Always run the test suite as the final step of any implementation (use the `go-run-tests` skill to determine the right targets)

## Pre-Commit Review (MANDATORY)

Every commit MUST be preceded by an independent review by a subagent. No exceptions, including small fixes, Renovate MRs and "trivial" changes. Permission to commit/push does NOT waive the review.

1. **Run the reviewer** after lint and tests pass, before `git commit`:
   - `.go` files (incl. `go.mod`/`go.sum`) → `go-code-reviewer` subagent
   - Anything else (YAML, Dockerfile, Makefile, CI, docs, config) → `reviewer` subagent
   - Mixed diff → run both in parallel, each scoped to its files
   - Pass the subagent the repo path, what the change is meant to do, and the files changed. It starts with fresh context.
2. **Triage findings:**
   - **Critical / Major** → must be resolved before commit. The builder fixes them if the fix is clear-cut and within scope of the task.
   - **Ask the human** (do not commit) when a Critical/Major finding: needs a design decision, changes behavior or scope beyond the task, you disagree with it, or the fix is ambiguous. State the finding, your recommendation, and the options.
   - **Minor / Nitpick** → fix if cheap and uncontroversial, otherwise skip. Never block on them.
   - A Critical/Major finding may be committed unfixed only if the human explicitly waives **that specific finding**. General commit/push permission is not a waiver.
3. **Re-review** after fixing Critical/Major findings: rerun the reviewer on the updated diff. At most 2 reviews in total (initial + 1 re-review) — if Critical/Major findings remain after that, stop and ask the human.
4. **Report** before committing: a short summary of findings, what was fixed, what was skipped and why. Never silently drop a Critical/Major finding.

## Skill Loading

CRITICAL: Use the `skill` tool to load skills on-demand based on the task at hand.

Instructions:

- Do NOT preemptively load all skills - use lazy loading based on actual need
- When loaded, treat skill content as mandatory instructions
- Load multiple skills when task spans different concerns (e.g., `go-idioms` + `go-test`)

### Skill Naming Convention

Skills follow the pattern `<language>-<skill>` for language-specific skills:

| Language | Prefix    | Examples                              |
| -------- | --------- | ------------------------------------- |
| Go       | `go-`     | `go-idioms`, `go-test`, `go-lint` |

Language-agnostic skills have no prefix: `docker-best-practices`

### Available Skills

Load skills with the `skill` tool when needed.

**Go Development:**

- `go-idioms` - Patterns, error handling, interfaces, naming
- `go-test` - Testing patterns and table-driven tests
- `go-run-tests` - Running the test suite (Makefile-first, with integration/component tags)
- `go-lint` - Running and fixing Go lint checks (Makefile-first, golangci-lint fallback)
- `go-benchmarks` - Writing and running benchmarks (b.Loop, b.N, benchstat)
- `go-mocks` - Mock generation with mockgen

**Tools:**

- `docker-best-practices` - Dockerfiles, multi-stage builds, container security
- `gitlab-mr` - GitLab merge request descriptions
- `gitlab-mr-review` - Post inline review comments on a GitLab MR's diff lines
- `commit` - Git commit messages in conventional format
- `aws-oidc-migration` - Migrate batman-configs services from static AWS keys to OIDC/IRSA
- `jira-task` - Create Jira tasks in the TECH project (efgcloud.atlassian.net)
- `renovate-mrs` - Verify, rebase, approve and merge Renovate MRs (Go repos only) + release summary

**Output Style:**

- `i-have-adhd` - ADHD-friendly output: action first, numbered steps, no fluff. Manual only; stays on until "stop adhd mode"

### When to Load Skills

| Task                      | Load Skill              |
| ------------------------- | ----------------------- |
| Writing Go code           | `go-idioms`             |
| Writing/running tests     | `go-test`               |
| Running the test suite    | `go-run-tests`          |
| Changing Go code          | `go-lint`               |
| Writing/running benchmarks| `go-benchmarks`         |
| Generating mocks          | `go-mocks`              |
| Writing Dockerfiles       | `docker-best-practices` |
| Creating a GitLab MR      | `gitlab-mr`             |
| Reviewing an MR / posting inline comments | `gitlab-mr-review` |
| Making a git commit       | `commit`                |
| Migrating a service to AWS OIDC | `aws-oidc-migration` |
| Creating a Jira task     | `jira-task`              |
| Processing Renovate MRs  | `renovate-mrs`           |
| User says "/i-have-adhd" or "adhd mode" | `i-have-adhd` |

### Missing Skills

If a task requires knowledge not covered by existing skills:

1. Check if a relevant skill exists in the `skill` tool's available_skills list
2. If not, research best practices from official documentation
3. Consider creating a new skill for reusable patterns

## Agents

Agents are invoked via the `subagent` tool (or `@agent-name` in the prompt):

```
subagent(agent="go-code-reviewer", prompt="Review code in internal/", description="Code review")
```

Run `/agents` to see all available agents.

| Agent                                          | Purpose                                         | When to Use                              |
| ---------------------------------------------- | ----------------------------------------------- | ---------------------------------------- |
| `go-code-reviewer`                             | Read-only Go review following Effective Go      | Before every commit touching Go code     |
| `reviewer`                                     | Read-only review of non-Go changes              | Before every commit touching non-Go files|
| `council-opus`, `council-fable`, `council-sonnet` | Independent opinions, combined via `/council` | Hard decisions, second opinions          |


## Quality Standards

- No hardcoded secrets
- Proper error handling
- Tests for new functionality
- Clear commit messages
