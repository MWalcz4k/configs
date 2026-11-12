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
- **Risk**: Always required. One level (Low / Medium / High) plus a 1–2 line justification: what could break, who/what is affected, and how it would show up (errors, metrics, alerts). Breaking changes, data migrations, and changes to payments, payouts or balances are never Low.
- **How to Revert**: Always required. Concrete rollback steps. Default is "Revert the MR and redeploy" (or just "Revert the MR" if nothing is deployed), but call out anything that makes that insufficient or unsafe: irreversible data/schema migrations, config or env vars to restore, feature flags to toggle, dependent services that must roll back first, or data written in the new format that the old version can't read.

## Style

- Keep it short and scannable.
- No walls of text.
- Summary: past tense, outcome-focused (e.g. "Fixed duplicate payouts when retries overlap").
