---
name: jira-task
description: >
  Create Jira tasks/tickets in the TECH project on efgcloud.atlassian.net.
  Load when asked to create a Jira task, file a ticket, open a Jira issue,
  or write up a task for Jira. Triggers: "create a jira task", "file a
  ticket", "open a jira issue", "raise a task in TECH".
license: MIT
compatibility: opencode
---

# Jira Task Creation

Use this skill to create Jira issues via the Jira MCP tools.

## Defaults

- **Cloud site**: `efgcloud.atlassian.net`
- **Project**: `TECH` (https://efgcloud.atlassian.net/jira/software/projects/TECH)
- **Issue type**: `Task`, unless the user specifies otherwise (e.g. Bug, Story)

Always confirm the project/issue type with the user only if they explicitly
ask for something other than the default — otherwise just use the defaults
silently.

## Required content

Every task description has exactly these four sections, **each rendered as
its own Jira "info" panel**, in this order:

1. **Description** — what the task is about, the problem or goal.
2. **Acceptance Criteria** — a checklist / bullet list of conditions that
   must be true for the task to be considered done.
3. **Technical Solution / Design** — how it will be implemented, notable
   technical decisions, affected components.
4. **Notes** — anything else: risks, open questions, links, caveats.

If the user hasn't given enough info for a section, ask them directly rather
than inventing content. It's fine for a section to be short (e.g. "N/A" for
Notes), but don't fabricate acceptance criteria or technical detail.

## Building the ADF description

Jira issue descriptions support info panels only via **ADF** (Atlassian
Document Format), not plain markdown. Use `contentFormat: "adf"` on
`jira_createJiraIssue` and pass the `description` as a stringified ADF `doc`.

Each section is a heading followed by an `info` panel:

```json
{
  "type": "doc",
  "version": 1,
  "content": [
    { "type": "heading", "attrs": { "level": 3 }, "content": [{ "type": "text", "text": "Description" }] },
    {
      "type": "panel",
      "attrs": { "panelType": "info" },
      "content": [
        { "type": "paragraph", "content": [{ "type": "text", "text": "<description text>" }] }
      ]
    },
    { "type": "heading", "attrs": { "level": 3 }, "content": [{ "type": "text", "text": "Acceptance Criteria" }] },
    {
      "type": "panel",
      "attrs": { "panelType": "info" },
      "content": [
        {
          "type": "bulletList",
          "content": [
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "<criterion 1>" }] }] },
            { "type": "listItem", "content": [{ "type": "paragraph", "content": [{ "type": "text", "text": "<criterion 2>" }] }] }
          ]
        }
      ]
    },
    { "type": "heading", "attrs": { "level": 3 }, "content": [{ "type": "text", "text": "Technical Solution / Design" }] },
    {
      "type": "panel",
      "attrs": { "panelType": "info" },
      "content": [
        { "type": "paragraph", "content": [{ "type": "text", "text": "<technical solution text>" }] }
      ]
    },
    { "type": "heading", "attrs": { "level": 3 }, "content": [{ "type": "text", "text": "Notes" }] },
    {
      "type": "panel",
      "attrs": { "panelType": "info" },
      "content": [
        { "type": "paragraph", "content": [{ "type": "text", "text": "<notes text>" }] }
      ]
    }
  ]
}
```

Notes on ADF construction:

- Use `bulletList` (as above) for Acceptance Criteria — it's almost always a
  list, not prose.
- Multiple paragraphs within one panel are allowed — just add more
  `paragraph` nodes to that panel's `content` array.
- Every `panel` must have `attrs.panelType: "info"`.
- Don't wrap the whole doc in an outer panel — one panel per section only.

## Workflow

1. Gather/confirm: summary (issue title), and the four section contents.
   Ask clarifying questions for anything missing or vague.
2. Build the ADF `doc` as shown above.
3. Call `jira_createJiraIssue` with:
   - `cloudId`: `efgcloud.atlassian.net`
   - `projectKey`: `TECH` (unless told otherwise)
   - `issueTypeName`: `Task` (unless told otherwise)
   - `summary`: the title
   - `description`: the ADF doc, stringified
   - `contentFormat`: `"adf"`
4. Report back the created issue key and a link:
   `https://efgcloud.atlassian.net/browse/<KEY>`.

## Style

- Description: 2-4 sentences, plain prose.
- Acceptance Criteria: bullet points, testable/verifiable statements, not
  vague ("Users can filter by date" not "Filtering works well").
- Technical Solution / Design: can include bullet points if there are
  multiple discrete decisions; otherwise prose.
- Notes: short, only include what's relevant — omit filler like "N/A" only
  if the user explicitly has nothing to add, otherwise ask.
