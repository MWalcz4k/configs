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

- <High-level change 1>
- <High-level change 2>
- ...

## Breaking Changes

<only include this section if there are breaking changes>

## New Required Config

<only include this section if there are new required config values>
```

## Rules

- **Task**: Extract the Jira ticket number from the current branch name (e.g. `feature/PROJ-123-some-thing` → `PROJ-123`). If no ticket is found, leave it blank and ask the user.
- **Summary**: Bullet points only. High-level summary of what changed — not an exhaustive list of every decision made. Write for someone who wasn't in the weeds — they should understand *what* changed and *why*, not *how*.
- **Breaking Changes**: List anything that breaks backward compatibility (API changes, removed fields, renamed config keys, changed behavior). **Omit this section entirely if there are none.**
- **New Required Config**: List any new environment variables or config values that are required to run the application after this change. Include the variable name and a short description. **Omit this section entirely if there are none.**

## Style

- Keep it short and scannable.
- No walls of text.
- Past tense for changes ("Added", "Removed", "Updated", "Fixed").
