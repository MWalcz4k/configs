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
- After changing Go code, load `go-lint`, run the project's lint command, and fix lint failures before running tests
- Always run the test suite as the final step of any implementation (use the `go-run-tests` skill to determine the right targets)

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
- `commit` - Git commit messages in conventional format

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
| Making a git commit       | `commit`                |

### Missing Skills

If a task requires knowledge not covered by existing skills:

1. Check if a relevant skill exists in the `skill` tool's available_skills list
2. If not, research best practices from official documentation
3. Consider creating a new skill for reusable patterns

## Agents

Agents are invoked via the `task` tool with the `subagent_type` parameter:

```
task(subagent_type="go-code-reviewer", prompt="Review code in internal/", description="Code review")
```

Run `/agents` to see all available agents.

| Agent              | Purpose                            | When to Use                           |
| ------------------ | ---------------------------------- | ------------------------------------- |
| `go-code-reviewer` | Code review following Effective Go | Before commits/PRs, reviewing Go code |


## Quality Standards

- No hardcoded secrets
- Proper error handling
- Tests for new functionality
- Clear commit messages
