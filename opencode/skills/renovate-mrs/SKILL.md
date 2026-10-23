---
name: renovate-mrs
description: >
  Process Renovate merge requests where I'm a reviewer: ensure repos are cloned,
  verify each MR builds/lints/tests, prompt me to fix issues, rebase onto
  origin/master, approve and merge when mergeable, then summarise which repos
  need releasing. Triggers: "renovate MRs", "process renovate", "merge renovate",
  "dependency update MRs", "review renovate MRs".
license: MIT
compatibility: opencode
---

# Renovate MR Sweep

Work through every open Renovate MR where I'm a reviewer, one at a time.
Workspace: `~/workspace` (one directory per repo, named after the project's
last path segment). Do NOT use go workspaces or vendor.

## Prerequisites

- `glab` authenticated (`glab auth status`). Username: `glab api user | jq -r .username`.
- `jq` installed.

## 1. List MRs

```bash
ME=$(glab api user | jq -r .username)
glab api "merge_requests?reviewer_username=$ME&state=opened&scope=all&per_page=100" --paginate \
  | jq -r '.[] | select(.source_branch|startswith("renovate"))
           | [.project_id, .iid, .references.full, .source_branch, .target_branch, .title, .web_url] | @tsv'
```

**Scope: Go repositories only.** After cloning (step 2), keep only repos
with a `go.mod` at the root (or in a subdir). Skip Java/Maven (`pom.xml`),
Node, and other non-Go repos entirely — don't verify, approve, or merge them;
list them under "Skipped (not Go)" in the final summary.

**Ignore archived repositories.** Archived projects can't be merged into and
their Renovate MRs are stale noise. Check each distinct project before doing
anything else with it:

```bash
glab api projects/<project_id> | jq -r .archived   # true => ignore
```

Drop archived projects entirely: don't clone, verify, approve, or merge them.
List them under "Skipped / blocked" in the final summary with reason "archived".

Show the list to me as a table (repo, MR, title) and track each MR as a todo.
Process same-repo MRs back-to-back; after merging one, the others in that
repo usually need a rebase.

**Batching: work on at most 3 repos at a time.** Take the next 3 repos (with
all their MRs), fully finish them (verify, push, pipeline, ask me, merge or
skip), and only then start the next batch of up to 3. Never verify or run
tests for more than 3 repos in one go.

## 2. Ensure repos are cloned

For each project path, `dir=$(basename $path)`. Match against existing repos by
`origin` URL (a dir may have a different name, e.g. `engagement` →
`engagement-service`). If missing:

```bash
git clone git@gitlab.com:<project-path>.git ~/workspace/<dir>
```

## 3. Per MR loop

### a. Check out & rebase

```bash
cd ~/workspace/<dir>
git status --porcelain            # if dirty: STOP and ask me (never stash/discard silently)
git fetch origin
git checkout -B <source_branch> origin/<source_branch>
git rebase origin/<target_branch>  # target is usually master
```

On conflicts in lock/sum files (`go.sum`, `package-lock.json`, `pnpm-lock.yaml`):
take the target side, then regenerate with `go mod tidy`. Other conflicts: ask me.

### b. Verify it works

Go only (Makefile targets first): load `go-lint` and `go-run-tests` skills.
Run `go build ./...`, `go mod tidy` (must leave no diff), lint, tests.

Also check the MR pipeline: `glab ci status -b <source_branch>` or
`glab api projects/<id>/merge_requests/<iid> | jq .head_pipeline.status`.

For **major** bumps (title contains `to v<N>` with a new major, e.g. module
`/v2`, mongo-driver v2): read the changelog/migration notes,
grep the code for broken APIs, and expect code changes.

### c. Failures → prompt me

If anything fails, summarise the error and propose a fix, then use the
`question` tool with options: **Fix it** (apply fix, re-run checks), **I'll fix
it manually** (wait, then re-verify), **Skip this MR**, **Redundant – delete branch**.
Never push a fix without my OK.

### Flaky tests

If a test fails intermittently (passes on re-run, or the failure is unrelated
to the dependency bump — timing, ordering, shared state, races, ports, time.Now):

1. Confirm flakiness: `go test -run '^TestName$' -count=20 -race ./pkg/...`.
2. Find the root cause and fix it properly (sync instead of `time.Sleep`,
   `t.Parallel()` isolation, deterministic ordering, `t.Cleanup`, fake clocks).
   Don't just add retries or skip the test.
3. Re-run with `-count=20 -race` to prove it's stable, then lint.
4. Show me the fix, and after I confirm, commit it **into the Renovate branch** as a
   separate commit (`commit` skill style, e.g. `test(<pkg>): fix flaky TestX`)
   and push with `--force-with-lease`. Fixing a flaky test is fine even if
   it's unrelated to the bump.
5. Note it in the final summary (column "Extra fixes").

### Redundant MRs

If an MR is redundant (already applied on master, superseded by a newer
Renovate MR, stale digest, etc.), **do NOT close the MR** — Renovate treats a
closed MR as "ignore this update forever". Instead delete the source branch
(after my confirmation); GitLab closes the MR automatically and Renovate
recreates it later if still relevant:

```bash
git push origin --delete <source_branch>
# or: glab api -X DELETE "projects/<id>/repository/branches/$(jq -rn --arg b <source_branch> '$b|@uri')"
```

### d. Push

Only if the branch changed (rebase or fixes):

```bash
git push --force-with-lease origin <source_branch>
```

Commit fixes using the `commit` skill style (e.g. `fix(deps): adapt to <pkg> vX`).
Then wait for the pipeline (`glab ci status -b <branch> --live` or poll every 30s)
until it is `success`. Failed pipeline → back to step c.

### e. Approve & merge

Check mergeability:

```bash
glab api projects/<id>/merge_requests/<iid> \
  | jq '{detailed_merge_status, has_conflicts, pipeline: .head_pipeline.status}'
```

Only if `detailed_merge_status == "mergeable"` (or `not_approved` before
approval) and pipeline `success`:

```bash
glab mr approve <iid> -R <project-path>
glab mr merge <iid> -R <project-path> --remove-source-branch --yes
```

Use squash only if the project requires it (`squash_option` = `always`/`default_on`).
If not mergeable (needs other approvals, blocked discussions, etc.) record the
reason and move on. Then `git checkout master && git pull --ff-only`.

## 4. Release summary

At the end, for every repo where at least one MR was merged, check unreleased
changes:

```bash
git fetch --tags origin
last=$(git describe --tags --abbrev=0 origin/master 2>/dev/null)
git log --oneline ${last:+$last..}origin/master
```

Output:

```
## Merged
| Repo | MR | Title | Extra fixes (flaky tests etc.) |

## Needs release
| Repo | Last tag | Commits since tag | Notes (major bump / lib vs service) |

## Skipped / blocked
| Repo | MR | Reason (incl. "archived") |

## Skipped (not Go)
| Repo | MR | Language |
```

Flag libraries (`gokit`, `go-tools`, `go-broker-commons`, etc.) separately — releasing them triggers follow-up Renovate MRs
in consumers.
