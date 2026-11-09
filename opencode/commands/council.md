---
description: Ask a council of models (Claude Opus, Claude Fable, Claude Sonnet) and get a combined verdict
---

Convene the council on this question:

$ARGUMENTS

Steps:
1. In a SINGLE message, start three parallel `subagent` calls with agent `council-opus`, `council-fable` and `council-sonnet`. Give each the identical, self-contained prompt: the question plus any context they need (file paths, relevant code, constraints). Don't push them toward an answer.
2. When all three reply, write:
   - **Consensus**: where they agree
   - **Disagreements**: who said what, and which argument is stronger
   - **Unique catches**: points only one model raised
   - **Verdict**: your final recommendation, with reasoning
Keep each member's raw answer out unless asked; quote briefly where useful.
