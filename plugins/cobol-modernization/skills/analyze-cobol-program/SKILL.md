---
name: analyze-cobol-program
description: |
  Parses a single Enterprise COBOL source program (and its directly COPY-ed
  copybooks, if provided) and emits a deterministic, machine-readable
  "program profile" plus a short human brief. The profile enumerates
  divisions, sections, paragraphs, the PERFORM call graph, CALL'd
  sub-programs, COPY members, FD/SELECT file usage, EXEC SQL and EXEC CICS
  blocks, LINKAGE parameters, and complexity metrics (LOC, cyclomatic,
  paragraph fan-in / fan-out, nesting depth). USE this skill as the first
  per-program step of a COBOL-to-Java modernization pipeline, whenever you
  need a structural map of one program before extracting business rules,
  drawing diagrams, or transpiling. DO NOT use it for: (a) JCL job flow
  across multiple programs — use `map-mainframe-job-flow` instead;
  (b) deriving business rules in natural language — chain into
  `extract-cobol-business-rules`; (c) generating Mermaid diagrams directly
  — chain into `diagram-cobol-with-mermaid`; (d) repository-wide scans —
  use `scan-target-repo-patterns`. Inputs: one `*.cbl|*.cob|*.cobol` file
  and optionally a `copybooks/` folder. Outputs: `program-profile.json`
  and `program-brief.md` in the agent's working directory.
---

## Purpose

Produce a single, deterministic structural profile of one COBOL program
so that every downstream modernization skill (business-rule extraction,
diagramming, copybook conversion, transpilation, test generation) reads
the same canonical representation instead of re-parsing the source.

The profile is intentionally **shallow-semantic**: it records *what is
there* (paragraphs, files, calls, SQL) and *how it is wired*
(PERFORM/CALL edges), but it does **not** attempt to infer business
intent — that is the job of `extract-cobol-business-rules`.

## When to use / When not to use

Use when:

- You have one COBOL program and need a structural baseline before any
  other modernization skill runs against it.
- You need a reproducible JSON artifact to diff across refactors or to
  feed into a chain of skills.
- You need complexity metrics to prioritise programs for migration.

Do **not** use when:

- The input is JCL, a PROC, a copybook in isolation, or a CICS BMS map.
- You need cross-program reachability (use `map-mainframe-job-flow`).
- You need to render diagrams (use `diagram-cobol-with-mermaid`).
- You need a repo-wide inventory (use `scan-target-repo-patterns`).

## Inputs

Required:

1. `program_path` — absolute path to a single COBOL source file. Accepts
   `.cbl`, `.cob`, `.cobol`. Fixed-format (cols 7–72) and free-format
   are both supported; the workflow detects format from column 7.

Optional:

2. `copybook_dirs` — one or more directories searched (in order) to
   resolve `COPY <name>` and `COPY <name> REPLACING ...` statements.
3. `dialect` — one of `ibm-enterprise-cobol`, `gnucobol`, `micro-focus`.
   Defaults to `ibm-enterprise-cobol`.
4. `style_profile_path` — path to `target-repo-style-profile.json`
   produced by `scan-target-repo-patterns`. Not consumed structurally
   here, but its presence is recorded so downstream skills can chain.

## Workflow

Execute the steps in order. After each numbered step, write a one-line
checkpoint to the agent log so the run is resumable.

1. **Validate input.** Confirm `program_path` exists, is readable, and
   ends with an accepted extension. Reject directories. Detect source
   format by inspecting column 7 of the first 200 non-blank lines:
   if any line has `*`, `/`, `-`, or `D` in column 7, treat as fixed.
   Checkpoint: `format=<fixed|free>`.

2. **Normalize.** Strip sequence numbers (cols 1–6) and the identification
   area (cols 73–80) for fixed format. Preserve original line numbers
   in a side map `lineMap[normalizedLine] = originalLine` so that every
   later finding can be back-referenced. Do **not** lowercase reserved
   words — emit them as-written.

3. **Expand COPY (shallow, one level).** For each `COPY <name>
   [REPLACING ==a== BY ==b==]` directive, locate the copybook under
   `copybook_dirs`. If found, record the member name, file path,
   REPLACING pairs, and the inclusion site. If not found, record the
   member name with `resolved: false` and continue — do **not** abort.
   Recursive COPY-of-COPY is out of scope for this skill.

4. **Tokenise and segment.** Use an off-the-shelf open-source COBOL
   parser such as ProLeap or Koopa <!-- VERIFY --> to produce a
   division/section/paragraph tree. If no parser is available in the
   runtime, fall back to a regex segmenter that recognises:
   `IDENTIFICATION DIVISION`, `ENVIRONMENT DIVISION`,
   `DATA DIVISION`, `PROCEDURE DIVISION`, `SECTION.`, and paragraph
   headers (level-0 name followed by `.` in area A).

5. **Extract IDENTIFICATION facts.** `PROGRAM-ID`, `AUTHOR`,
   `DATE-WRITTEN`, `DATE-COMPILED` (if present). Record verbatim;
   do not normalise dates.

6. **Extract ENVIRONMENT facts.** For each `SELECT ... ASSIGN TO ...`
   in FILE-CONTROL, capture: logical name, system/DD name,
   organisation (`SEQUENTIAL` | `INDEXED` | `RELATIVE` | `LINE
   SEQUENTIAL`), access mode, record key(s), file-status variable.

7. **Extract DATA facts.**
   - `FILE SECTION`: every `FD` block, its record layout (top-level
     01-level name and PIC of the record).
   - `WORKING-STORAGE SECTION`: top-level 01 group names only (do not
     expand the full tree here — that is the copybook skill's job).
     Flag every `REDEFINES`, `OCCURS`, `OCCURS DEPENDING ON`, and
     `COMP-3` usage.
   - `LINKAGE SECTION`: ordered list of top-level 01 items.

8. **Extract PROCEDURE facts.** Build:
   - `paragraphs[]`: `{ name, section, startLine, endLine, loc }`.
   - `performEdges[]`: every `PERFORM <name>`, `PERFORM <name> THRU
     <name>`, `PERFORM ... VARYING`, `PERFORM ... UNTIL`. Capture
     target paragraph(s) and the inline condition text verbatim.
   - `callEdges[]`: every `CALL '<literal>' USING ...` or
     `CALL <identifier> USING ...`. Mark dynamic CALLs
     (`callType: "dynamic"`) when the target is an identifier.
   - `gotoEdges[]`: every `GO TO <name>` (flag as a smell).
   - `execSqlBlocks[]`: each `EXEC SQL ... END-EXEC` with the verb
     (`SELECT|INSERT|UPDATE|DELETE|DECLARE CURSOR|FETCH|OPEN|CLOSE|
     COMMIT|ROLLBACK`), referenced tables, and host variables
     (`:VAR`).
   - `execCicsBlocks[]`: each `EXEC CICS ... END-EXEC` with the verb
     (`READ|WRITE|REWRITE|LINK|XCTL|SEND MAP|RECEIVE MAP|RETURN|
     ABEND|...`).

9. **Compute metrics.**
   - `loc.total`, `loc.code`, `loc.comment` (lines with `*` in col 7).
   - `cyclomatic`: `1 + count(IF) + count(EVALUATE WHEN) +
     count(PERFORM ... UNTIL) + count(PERFORM ... VARYING) +
     count(WHEN OTHER excluded) + count(AND|OR in conditions)`.
   - For each paragraph: `fanOut = |performEdges from p|`,
     `fanIn = |performEdges to p|`, `maxNestingDepth` of IF/EVALUATE.
   - `deadParagraphs[]`: paragraphs with `fanIn == 0` and not the
     program entry (first paragraph of PROCEDURE DIVISION).

10. **Emit artifacts.** Write `program-profile.json` (schema below)
    and `program-brief.md` (≤ 60 lines) to the working directory.
    Both files MUST be deterministic for a given input: sort arrays
    by `startLine`, then by `name`.

### Program-profile JSON schema (informative)

```jsonc
{
  "schemaVersion": "1.0",
  "source": { "path": "...", "dialect": "...", "format": "fixed|free",
              "sha256": "..." },
  "identification": { "programId": "...", "author": "...",
                      "dateWritten": "..." },
  "environment": { "files": [ { "logicalName": "...", "ddName": "...",
                                "organization": "...", "accessMode": "...",
                                "recordKey": "...", "statusVar": "..." } ] },
  "data": {
    "fileSection":    [ { "fd": "...", "record01": "..." } ],
    "workingStorage": [ { "name": "...", "flags": ["REDEFINES","OCCURS",
                                                   "OCCURS DEPENDING ON",
                                                   "COMP-3"] } ],
    "linkage":        [ { "name": "..." } ],
    "copybooks":      [ { "member": "...", "resolvedPath": "...|null",
                          "replacing": [["==a==","==b=="]],
                          "includedAtLine": 0 } ]
  },
  "procedure": {
    "paragraphs":     [ { "name": "...", "section": "...",
                          "startLine": 0, "endLine": 0, "loc": 0,
                          "fanIn": 0, "fanOut": 0,
                          "maxNestingDepth": 0 } ],
    "performEdges":   [ { "from": "...", "to": "...",
                          "kind": "SIMPLE|THRU|VARYING|UNTIL",
                          "condition": "...|null", "line": 0 } ],
    "callEdges":      [ { "from": "...", "target": "...",
                          "callType": "static|dynamic", "line": 0,
                          "using": ["...","..."] } ],
    "gotoEdges":      [ { "from": "...", "to": "...", "line": 0 } ],
    "execSqlBlocks":  [ { "verb": "...", "tables": ["..."],
                          "hostVars": [":VAR"], "line": 0 } ],
    "execCicsBlocks": [ { "verb": "...", "args": { }, "line": 0 } ]
  },
  "metrics": {
    "loc": { "total": 0, "code": 0, "comment": 0 },
    "cyclomatic": 0,
    "deadParagraphs": ["..."]
  },
  "chaining": { "styleProfileSeen": true }
}
```

## Validation

The agent MUST run all checks before declaring success. Each check
either passes or appends a structured warning to
`program-profile.json#/warnings[]`. Hard-fail only on V1–V3.

- **V1 (hard).** Output file `program-profile.json` is valid JSON and
  conforms to the schema above (all required keys present, arrays
  present even when empty).
- **V2 (hard).** Every `performEdges[].to`, `callEdges[].from`, and
  `gotoEdges[].from` references either an existing paragraph in
  `paragraphs[]` or is marked `external: true` (CALL targets only).
- **V3 (hard).** `identification.programId` is non-empty and matches
  `/^[A-Z0-9][A-Z0-9-]{0,7}$/` (Enterprise COBOL 8-char limit
  <!-- VERIFY -->). If the source declares a longer name, record it
  verbatim and emit warning `W-PROGID-TOO-LONG`.
- **V4.** Every `COPY` site has either `resolvedPath` set or warning
  `W-COPY-UNRESOLVED:<member>`.
- **V5.** `metrics.cyclomatic >= 1`. If `> 50`, emit
  `W-HIGH-COMPLEXITY` so downstream skills can chunk.
- **V6.** `metrics.deadParagraphs` is a subset of
  `procedure.paragraphs[].name`. If non-empty, emit `W-DEAD-CODE`.
- **V7.** `source.sha256` of the normalised source is recorded so
  downstream skills can detect drift.
- **V8.** `program-brief.md` is ≤ 60 lines and references the JSON
  file path in its first line.

## Common pitfalls

- **Fixed vs. free format.** Mis-detecting format produces a paragraph
  tree with one giant paragraph. Always run step 1 explicitly.
- **Continuation lines.** A `-` in column 7 continues a literal from
  the previous line. The normaliser must join continuations *before*
  tokenising, or string literals containing reserved words will be
  mis-parsed as PROCEDURE verbs.
- **COPY REPLACING.** Do not apply REPLACING to the copybook text in
  this skill — record the pairs verbatim. The copybook skill will
  apply them when it converts to a Java record.
- **Dynamic CALL.** `CALL WS-PGM-NAME` cannot be resolved statically.
  Record `callType: "dynamic"` and the identifier name; do not guess.
- **PERFORM THRU.** Expands to all paragraphs between two names in
  source order; emit one `performEdges[]` entry per intermediate
  paragraph with `kind: "THRU"`.
- **EXEC SQL host variables.** `:VAR` may appear inside `WHERE`,
  `INTO`, or `VALUES`. Capture all of them, not just `INTO`.
- **EVALUATE TRUE WHEN.** Each `WHEN` is a separate cyclomatic branch
  (except `WHEN OTHER`, which is the default fall-through).
- **GOBACK vs. STOP RUN vs. EXIT PROGRAM.** All three are program
  exits; record the form actually used (downstream skills care).
- **Nested programs.** If a second `PROGRAM-ID` appears inside the
  same source (END PROGRAM ... PROGRAM-ID ...), emit
  `W-NESTED-PROGRAMS` and analyse only the outer program; nested
  programs need their own invocation of this skill.

## Outputs

Written to the agent's current working directory:

1. `program-profile.json` — canonical structural profile (schema
   above). Consumed by every downstream modernization skill.
2. `program-brief.md` — human-readable summary: program id, purpose
   line (verbatim from the first `*>` / `*` comment block, if any),
   counts (paragraphs, performs, calls, SQL blocks), top-5 most
   fanned-in paragraphs, and any V4–V8 warnings.

Both files are idempotent: re-running the skill on an unchanged
source MUST produce byte-identical output (sort + stable formatting).

## Chaining

Upstream (optional):

- `scan-target-repo-patterns` — produces `target-repo-style-profile.json`
  referenced by `chaining.styleProfileSeen` for downstream skills.

Downstream (typical):

- `extract-cobol-business-rules` — reads `program-profile.json` to
  walk paragraphs in PERFORM order and extract rule statements.
- `diagram-cobol-with-mermaid` — reads `performEdges`, `callEdges`,
  and `execSqlBlocks` to render a Mermaid flowchart.
- `convert-copybook-to-java-record` — reads `data.copybooks[]` to
  decide which copybooks to convert.
- `map-vsam-db2-to-jpa` — reads `environment.files[]` and
  `procedure.execSqlBlocks[]` to derive JPA entities and repositories.
- `transpile-cobol-to-java21` — reads the full profile as its
  structural backbone.
- `generate-modernization-tests` — reads `metrics` and `paragraphs`
  to size and target characterisation tests.

