PHASE 2 — BUSINESS RULE EXTRACTION (PER-SLICE)

Trigger phrase from user: "Extract rules for slice <SLICE_ID>"
or "Extract rules for paragraphs X, Y, Z".

PRE-FLIGHT:
- Read STATE/repo-profile.md
- Read STATE/conversions/<PROGRAM_NAME>/01a-manifest.md
- Read ONLY STATE/conversions/<PROGRAM_NAME>/01b-analysis-<SLICE_ID>.md
- Read the COBOL ONLY for the line ranges of the paragraphs in this
  slice. Do not load unrelated parts.

PRODUCE exactly ONE file:

STATE/conversions/<PROGRAM_NAME>/02-rules-<SLICE_ID>.md

For each business rule found in this slice:

- RULE_ID (BR-<SLICE_ID>-001, BR-<SLICE_ID>-002, ...)
- Source: paragraph + line range
- Statement: one English sentence
- Inputs (data items)
- Conditions
- Actions
- Outputs (data items)
- Numeric precision (scale, RoundingMode for COMP-3 — cite
  repo-profile.md convention)
- Edge cases observed in code
- Open questions (numbered, max 5 per rule)

Add a DMN-style decision table ONLY for EVALUATE or deeply-nested IF
blocks. Skip simple branches.

End the chat with:
"Slice <SLICE_ID>: N rules extracted, M open questions.
Awaiting answers before any further slice or implementation."

STOP. Process only ONE slice per session.

DO NOT modify src/. DO NOT commit. DO NOT push. DO NOT run git.