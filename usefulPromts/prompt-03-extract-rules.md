PHASE 2 — EXTRACT BUSINESS RULES

PRE-FLIGHT:
- Read `STATE/repo-profile.md`.
- Read `STATE/conversions/<PROGRAM_NAME>/00-source.cbl` and `01-analysis.md`.
- Confirm conversion mode (FULL or PARTIAL) and targeted paragraphs.

If user answers to Phase 1 questions are missing, STOP and ask for them.

STEP A — Extract every business rule from the scope (full program or
selected paragraphs). For each rule produce:

  - RULE_ID (BR-001, BR-002, ...)
  - Source location (paragraph + line range)
  - Plain-English statement (one sentence)
  - Inputs (variables/fields involved)
  - Conditions (when this rule fires)
  - Actions (what it computes or decides)
  - Outputs (variables/fields written)
  - Edge cases observed in code
  - Open questions (numbered) — ASK rather than assume

STEP B — For numeric computations (especially COMP-3), explicitly state
the BigDecimal scale and RoundingMode you intend to use, citing the
repo-profile.md convention.

STEP C — Produce a DMN-style decision table for any EVALUATE or nested
IF that encodes branching policy.

STEP D — Write `STATE/conversions/<PROGRAM_NAME>/02-rules.md` with all
the above. End with a one-line summary in chat:
  "Extracted N rules; M open questions; awaiting answers."

If there are open questions, STOP and wait.

DO NOT commit. DO NOT modify src/.