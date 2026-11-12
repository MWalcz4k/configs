---
name: gitlab-mr
description: >
  Create GitLab merge request descriptions. Load when creating, drafting, or
  writing a GitLab MR description. Triggers: merge request, MR description,
  gitlab MR, open MR, create MR.
license: MIT
compatibility: opencode
---

# GitLab Merge Request Description

Use this skill when creating a GitLab merge request description.

## MR Description Template

```
## Task

<Jira task number, extracted from the branch name if not explicitly provided>

## Summary

- <What this MR achieves and why>
- <Further high-level outcome, if any>
- ...

## Breaking Changes

<only include this section if there are breaking changes>

## New Required Config

<only include this section if there are new required config values>

## Risk

<Low | Medium | High> — <what could go wrong and what is affected>

## How to Revert

<steps to roll back safely>
```

## Rules

- **Task**: Extract the Jira ticket number from the current branch name (e.g. `feature/PROJ-123-some-thing` → `PROJ-123`). If no ticket is found, leave it blank and ask the user.
- **Summary**: Always required. Bullet points only. Must make the clear intent behind the MR obvious — *why* it exists and *what* it achieves — so it can be understood without any knowledge of the code. Do not mention edited files, functions, types, or other code internals (user-facing names like endpoints, env vars or service names are fine when they clarify intent). High-level, not an exhaustive list of every decision made — explain *what* and *why*, not *how*.
- **Breaking Changes**: List anything that breaks backward compatibility (API changes, removed fields, renamed config keys, changed behavior). **Omit this section entirely if there are none.**
- **New Required Config**: List any new environment variables or config values that are required to run the application after this change. Include the variable name and a short description. **Omit this section entirely if there are none.**
- **Risk**: Always required. One level (Low / Medium / High) plus a 1–2 line justification: what could break, who/what is affected, what test coverage backs it, and how a failure would show up (errors, metrics, alerts).
  - Rate risk by **impact and confidence, not diff size**. A one-line change can be High; a large, well-tested, self-contained refactor can be Low.
  - Step 1 — **blast radius** ("components" = other services, DBs, queues, caches, external APIs):
    - Self-contained, no change to how the service interacts with other components → **Low**
    - Touches shared code or interactions with other components, including backward-compatible contract changes (e.g. additive API/message fields) and tuning (e.g. retries, timeouts, pool sizes, concurrency, rate limits, feature flag defaults) → **Medium**
    - Breaking or incompatible changes to a contract: removed/renamed fields, changed semantics of APIs/messages/events, DB schema migrations, auth → **High**
  - Step 2 — **confidence**: if the changed paths aren't tested, go up one level (max High). For interactions with other components, "tested" means exercised against the real contract (integration/component/contract tests) — mocked unit tests don't count. If you can't verify coverage, treat it as untested. Never go down a level because of tests.
  - Overrides (always win): breaking changes, data migrations, and changes to payments, payouts or balances are never Low.
- **How to Revert**: Always required. Concrete rollback steps. Default is "Revert the MR and redeploy" (or just "Revert the MR" if nothing is deployed), but call out anything that makes that insufficient or unsafe: irreversible data/schema migrations, config or env vars to restore, feature flags to toggle, dependent services that must roll back first, or data written in the new format that the old version can't read.

## Style

- Keep it short and scannable.
- No walls of text.
- Summary: past tense, outcome-focused (e.g. "Fixed duplicate payouts when retries overlap").
