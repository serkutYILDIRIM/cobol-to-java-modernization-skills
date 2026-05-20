PHASE 1 — ANALYZE A COBOL PROGRAM

INPUT: The user will EITHER paste the COBOL source into chat, OR provide
a path to a file under `.copilot-conversion/inbox/`. First action: ask
which one, and ask for the conversion mode:
  - FULL (convert the entire program), or
  - PARTIAL (convert only specific paragraphs / business rules listed
    by the user)

PRE-FLIGHT: Read `STATE/repo-profile.md`. If missing, STOP and tell the
user to run prompt-01-scan-repo.md first.

STEP A — IDENTIFY PROGRAM_NAME from the PROGRAM-ID. Create:
  `.copilot-conversion/STATE/conversions/<PROGRAM_NAME>/00-source.cbl`
  with the exact COBOL source (or a reference if it came from a file).

STEP B — PRODUCE `01-analysis.md` containing:

  1. Program metadata
     - PROGRAM-ID, author (if present), source LOC
     - Mode requested (FULL or PARTIAL — list targeted paragraphs)

  2. Structure
     - DIVISIONs and SECTIONs
     - All paragraphs with line ranges
     - PERFORM call graph (Mermaid `flowchart`)
     - COPYBOOK dependencies (resolved if available, listed as TODO if not)

  3. Data model
     - File section: files opened, organization, record layouts
     - Working-storage: every group/elementary item with PIC, USAGE, scale
     - Linkage section (if any)
     - REDEFINES and OCCURS — flag REDEFINES for user clarification

  4. I/O surface
     - File I/O (READ/WRITE/REWRITE)
     - EXEC SQL statements (list tables/columns; map to repo entities
       if obvious, otherwise mark as TODO)
     - EXEC CICS commands (if any)
     - CALL statements to external programs

  5. Control flow & complexity
     - Cyclomatic complexity per paragraph
     - Dead code candidates
     - EVALUATE/IF nesting depth hotspots

  6. Questions for the user (numbered, max 7)
     - Any REDEFINES needing intent clarification
     - Any external CALLs whose contract is unknown
     - Any DB2 tables not present in the repo

STEP C — STOP and wait for the user to answer the questions before
proceeding to Phase 2. Do not guess.

DO NOT commit. DO NOT modify src/.