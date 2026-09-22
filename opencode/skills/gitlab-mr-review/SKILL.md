---
name: gitlab-mr-review
description: >
  Review a branch/MR's changes and post the findings as inline comments on
  specific diff lines in a GitLab merge request. Load when asked to review
  an MR, post review comments on a GitLab MR, leave line comments on a merge
  request, or comment on specific lines of a diff. Triggers: "review this MR",
  "post comments on the MR", "leave inline comments", "comment on the diff",
  glab, GitLab merge request review.
license: MIT
compatibility: opencode
---

# GitLab MR Line-by-Line Review

Use this skill to review code changes and post the feedback as **inline
diff comments** (attached to exact file/line) on a GitLab merge request,
instead of dumping a wall of text as a single note.

## Prerequisites

- `glab` must be installed and authenticated (`which glab`).
- The repo's `origin` remote must point to the GitLab project.

## Workflow

### 1. Review the changes

- Diff the branch against its base: `git diff origin/master...HEAD` (or
  whatever the MR's target branch is).
- For Go code, load `go-idioms` and/or use the `go-code-reviewer` subagent
  via the `task` tool to get a structured review (Critical/Major/Minor/Nitpick).
- Only pick the findings you actually want posted as line comments — keep
  each comment short, specific, and tied to one exact line. Don't post
  comments for generated/mock files unless something is genuinely wrong.

### 2. Find the MR and get diff refs

```bash
glab mr view                     # confirms the MR for the current branch, prints its number
```

Get the exact `base_sha` / `start_sha` / `head_sha` GitLab needs to anchor
comments to lines (these are NOT just `git rev-parse` of local branches —
pull them straight from the MR):

```bash
PROJECT="<url-encoded-namespace%2Fpath>"   # e.g. group%2Fsubgroup%2Frepo
glab api "projects/${PROJECT}/merge_requests/<IID>" | \
  python3 -c "import json,sys; print(json.load(sys.stdin)['diff_refs'])"
```

This returns `{"base_sha": "...", "head_sha": "...", "start_sha": "..."}`.

### 3. Find the exact line numbers

For each finding, get the line number **in the new version of the file**
(post-change):

```bash
grep -n "the thing you're commenting on" path/to/file.go
```

Use the line number as it appears in the current (HEAD) version of the file
for `new_line`. If commenting on a removed/old line instead, use `old_line`
and drop `new_line`.

### 4. Post inline comments

**Important:** `glab api -f "position[base_sha]=..."` (bracket-notation
fields) does **NOT** work — GitLab's discussions endpoint needs a real nested
JSON body, and `glab`'s `-f`/`--raw-field` flags don't expand bracket keys
into nested objects. This silently creates a plain top-level note (type
`DiscussionNote`) instead of a line-anchored one (type `DiffNote`), with no
error to warn you.

**Always build the JSON payload as a file and pass it with `--input`, plus
an explicit `Content-Type: application/json` header** (glab does not set
this automatically for `--input`):

```bash
PROJECT="<url-encoded-namespace%2Fpath>"
MR_IID=85
BASE_SHA="..."; START_SHA="..."; HEAD_SHA="..."

cat > /tmp/note.json <<JSON
{
  "body": "short, direct comment about this exact line",
  "position": {
    "base_sha": "$BASE_SHA",
    "start_sha": "$START_SHA",
    "head_sha": "$HEAD_SHA",
    "position_type": "text",
    "new_path": "path/to/file.go",
    "old_path": "path/to/file.go",
    "new_line": 42
  }
}
JSON

glab api "projects/${PROJECT}/merge_requests/${MR_IID}/discussions" \
  --input /tmp/note.json -H "Content-Type: application/json"
```

Repeat per finding (one API call per comment/line). Verify each response has
`"type":"DiffNote"` and a populated `"position"` block — if you see
`"DiscussionNote"` with no position, the comment landed as a generic note,
not on a line, and needs to be deleted and redone.

### 5. Verify

List discussions and confirm each one you posted has `type: DiffNote` with
the expected `new_path`/`new_line`:

```bash
glab api "projects/${PROJECT}/merge_requests/${MR_IID}/discussions" | \
  python3 -m json.tool
```

### 6. Cleanup (if needed)

To delete a note (e.g. a botched plain comment that should've been inline):

```bash
glab api "projects/${PROJECT}/merge_requests/${MR_IID}/notes/<note_id>" -X DELETE
```

## Comment Style

- Short and to the point — like a human reviewer leaving a quick line note,
  not an essay. One or two sentences max.
- Skip praise/explanation unless asked; go straight to the issue and the fix.
- One comment per finding/line. Don't bundle unrelated issues into one note.

## Rules

- Never post comments without first confirming the MR (`glab mr view`) and
  the diff_refs belong to the branch/MR being reviewed.
- Always ask for confirmation before posting comments to a real MR, unless
  the user has already explicitly asked for it in this conversation.
- Don't silently swallow a `DiscussionNote` fallback — check the response
  `type` after every post.
