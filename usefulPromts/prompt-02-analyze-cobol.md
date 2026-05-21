PHASE 1 — COBOL ANALYSIS (CHECKPOINTED, KEYWORD-FIRST)

This phase handles COBOL programs of ANY size, including 10K+ lines.
It uses keyword/regex search FIRST and semantic analysis LAST.

═══════════════════════════════════════════════════════════════════════
STEP 0 — INTAKE INTERVIEW (always first)
═══════════════════════════════════════════════════════════════════════

Ask the user these numbered questions:

1. COBOL file path (under .copilot-conversion/inbox/)?
2. Conversion MODE: FULL or PARTIAL?
3. If PARTIAL: what should drive the selection?
   a) Specific paragraph names (please list them)
   b) Business keywords (e.g., TAX, PAYROLL, INTEREST) — agent will
   search and present matching paragraphs for confirmation
   c) Input/output field names (e.g., NET-PAY, EMPLOYEE-ID)
   d) A specific feature/use case the user describes in 1-2 sentences

Wait for answers.

═══════════════════════════════════════════════════════════════════════
STEP 1 — LOC CHECK & STRATEGY SELECTION
═══════════════════════════════════════════════════════════════════════

Read ONLY the file size and line count (using `wc -l` or equivalent;
do NOT load the contents yet). Report:

PROGRAM_NAME (from PROGRAM-ID — grep line 1–30)
Total LOC
Suggested strategy:
LOC ≤ 500          → SMALL  (single-session Pass A + Pass B ok)
500 < LOC ≤ 2000   → MEDIUM (Pass A one session; Pass B per slice)
LOC > 2000         → LARGE  (Pass A chunked into stages;
Pass B strictly per slice)

End chat with:
"PROGRAM_NAME: <name>, LOC: <n>, strategy: <S/M/L>.
Reply `continue` to start Pass A."

STOP and wait.

═══════════════════════════════════════════════════════════════════════
STEP 2 — PASS A: STRUCTURAL MANIFEST (CHUNKED FOR LARGE)
═══════════════════════════════════════════════════════════════════════

Trigger: user says `continue`.

GOAL: produce a manifest WITHOUT loading the whole file into your
context. Strategy depends on size:

SMALL/MEDIUM:
Use grep/regex over the whole file in one pass to extract:
DIVISION/SECTION lines, paragraph headers, COPY, EXEC SQL,
EXEC CICS, CALL, PERFORM. Build the manifest in one shot.

LARGE:
Split the file into windows of 2000 lines (W1, W2, W3, ...).
For each window:
- Use grep/regex to extract the same structural tokens.
- Append to STATE/conversions/<PROGRAM_NAME>/manifest-windows/
window-<NN>.md  (one file per window)
- STOP and ask user to reply `continue` for the next window.

After all windows are processed (or in one shot for S/M), MERGE them
into a single file:

STATE/conversions/<PROGRAM_NAME>/01a-manifest.md

Sections (concise, table-driven):
1. Program metadata (PROGRAM-ID, LOC, strategy, mode)
2. Division & section index (line ranges)
3. Paragraph index (THE KEY TABLE)
   | Paragraph | Line range | LOC | PERFORM targets | Called by |
   I/O? | DB? | Complexity hint |
4. Data area index (working-storage only, group/elementary items
   with PIC/USAGE, REDEFINES, OCCURS)
5. External surface (COPYBOOK, EXEC SQL, EXEC CICS, CALL)
6. PERFORM call graph (Mermaid flowchart, paragraph names only)
7. Open structural questions (numbered, max 5)

End chat with:
"Pass A complete. Manifest written.
Reply `partial-search <keywords>` to locate target paragraphs for
PARTIAL mode, or `slice-plan` to propose a slicing strategy for
FULL mode."

STOP.

═══════════════════════════════════════════════════════════════════════
STEP 3 — PARTIAL MODE: KEYWORD-DRIVEN PARAGRAPH DISCOVERY
═══════════════════════════════════════════════════════════════════════

Trigger: user says `partial-search <keywords>` OR user provided
keywords/fields/feature in STEP 0.

EXECUTION:
1. Combine user-provided keywords with morphological variants
   (e.g., TAX → TAX, TAXABLE, TAX-RATE, COMP-TAX).
2. Use case-insensitive grep across the COBOL file to find ALL
   matching lines. Limit to first 50 hits.
3. Map each hit to its enclosing paragraph using the manifest.
4. Produce a candidate paragraph table in chat:
   | # | Paragraph | Line range | Hit lines | Hit snippets (≤ 80 chars) |
5. Ask the user (numbered):
     1. Which paragraphs should be in scope? (reply with #s)
     2. Any paragraphs called BY the selected ones that should also
        be included? (agent suggests them from the manifest call graph)

After the user confirms, write:
STATE/conversions/<PROGRAM_NAME>/01a-scope.md
listing the final selected paragraphs and their reason for inclusion.

End chat with:
"Scope confirmed: N paragraphs. Reply `continue` to begin Pass B
slice planning."

STOP.

═══════════════════════════════════════════════════════════════════════
STEP 4 — SLICE PLAN (FOR PASS B)
═══════════════════════════════════════════════════════════════════════

Trigger: user says `continue` (after STEP 3) or `slice-plan` (FULL mode).

Read manifest + (if PARTIAL) 01a-scope.md. Propose slices of 5–10
paragraphs each, grouped by shared data + call proximity. Each slice:
- Slice ID (S1, S2, ...)
- Paragraphs included
- Total LOC
- Theme guess (mark GUESS)
- Dependencies on other slices

Write `STATE/conversions/<PROGRAM_NAME>/01a-slice-plan.md`.

End chat with:
"Slice plan ready. <N> slices.
Reply `pass-b <SLICE_ID>` to analyze a slice (start with S1)."

STOP.

═══════════════════════════════════════════════════════════════════════
STEP 5 — PASS B: PER-SLICE SEMANTIC ANALYSIS
═══════════════════════════════════════════════════════════════════════

Trigger: user says `pass-b <SLICE_ID>`.

PRE-FLIGHT:
- Read STATE/repo-profile.md
- Read 01a-manifest.md and 01a-slice-plan.md
- Read 01a-scope.md if it exists
- READ ONLY the line ranges of the paragraphs in this slice from
  the COBOL source. NEVER the whole file again.

Because the candidate set is now SMALL (≤ 10 paragraphs, typically
< 1000 lines), this is where you APPLY DEEP SEMANTIC ANALYSIS.

Write ONE file:
STATE/conversions/<PROGRAM_NAME>/01b-analysis-<SLICE_ID>.md

Sections:
1. Slice summary (paragraphs, LOC, business theme — confirmed)
2. Per-paragraph deep analysis:
     - Purpose (1–2 sentences)
     - Inputs (data items, qualifications)
     - Outputs (data items written, side effects)
     - Local control flow (IF/EVALUATE/PERFORM VARYING)
     - I/O and DB touchpoints (tables, columns)
     - Numeric precision (PIC, USAGE, intended BigDecimal scale,
       RoundingMode)
     - Edge cases visible in code
3. Cross-paragraph data flow (Mermaid sequence if helpful)
4. Open semantic questions (numbered, max 5)

End chat with:
"Pass B for <SLICE_ID> complete. Next slice: <NEXT_SLICE_ID>.
Reply `pass-b <NEXT_SLICE_ID>` or `done` if all slices analyzed."

STOP.

═══════════════════════════════════════════════════════════════════════
ABSOLUTE RULES (PHASE 1)
═══════════════════════════════════════════════════════════════════════

- Never load the whole COBOL into context.
- Keyword/grep first, semantic last.
- One checkpoint = one chat response. Always STOP and wait for `continue`
  or another trigger phrase.
- Never modify src/.
- Never commit, push, or run git.
- If you see context approaching ~70% capacity, STOP early and split.