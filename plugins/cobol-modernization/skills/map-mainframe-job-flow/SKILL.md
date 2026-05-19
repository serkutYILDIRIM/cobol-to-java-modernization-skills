---
name: map-mainframe-job-flow
description: |
  Parses one or more z/OS JCL job streams (and any in-stream or cataloged
  PROCs you provide) and emits a deterministic, machine-readable
  "job-flow profile" plus a short human brief. The profile enumerates
  JOB cards, EXEC PGM= / EXEC PROC= steps, expanded PROC steps with
  symbolic parameter substitution, DD statements with DSN / DISP /
  organization, JOBLIB / STEPLIB / JCLLIB, COND and IF/THEN/ELSE/ENDIF
  control flow, RESTART / CHKPT, GDG references, instream SYSIN, plus
  cross-step and cross-job dataset dependencies derived from
  DISP=(NEW|OLD|SHR|MOD,…) read-after-write edges. USE this skill
  whenever you need to understand WHICH programs run in WHICH order,
  with WHICH datasets, before extracting business rules or planning a
  Strangler-Fig migration of a batch suite. DO NOT use it for: (a) a
  single COBOL program's internal call graph — use `analyze-cobol-program`;
  (b) repo-wide language/build inventory — use `scan-target-repo-patterns`;
  (c) rendering Mermaid diagrams directly — chain into
  `diagram-cobol-with-mermaid`; (d) deriving JPA entities from DB2/VSAM —
  chain into `map-vsam-db2-to-jpa`. Inputs: one or more `*.jcl` files and
  optionally a `procs/` folder of cataloged PROCs. Outputs: `job-flow.json`
  and `job-flow.md` in the agent's working directory.
---

## Purpose

Produce a single, deterministic flow profile of one or more batch JCL
jobs so that every downstream modernization skill (business-rule
extraction, diagramming, Strangler-Fig planning, test generation)
reads the same canonical orchestration graph instead of re-parsing
JCL.

The profile is intentionally **orchestration-level**: it records
*which* program runs in *which* step under *which* condition, and
*which* datasets flow between steps and jobs. It does **not** parse
the COBOL programs themselves — that is the job of
`analyze-cobol-program`, which this skill chains into per discovered
`EXEC PGM=`.

## When to use / When not to use

Use when:

- You have one or more JCL job streams and you need a structural,
  reproducible map of step order, programs called, and dataset flow.
- You need cross-job reachability (Job B reads a dataset Job A wrote)
  to scope a Strangler-Fig slice.
- You need to inventory every distinct `EXEC PGM=` before invoking
  `analyze-cobol-program` per program.

Do **not** use when:

- The input is a single COBOL program (use `analyze-cobol-program`).
- You want a repo-wide build/language inventory (use
  `scan-target-repo-patterns`).
- You want to render diagrams directly (use
  `diagram-cobol-with-mermaid`).
- You want database-schema-to-JPA mapping (use `map-vsam-db2-to-jpa`).

## Inputs

Required:

1. `jcl_paths` — one or more absolute paths to JCL files. Accepts
   `.jcl`, `.JCL`, `.job`. May be a single file or a list. Each file
   may contain one or more `//<jobname> JOB ...` cards.

Optional:

2. `proc_dirs` — one or more directories searched (in order) to
   resolve cataloged `EXEC PROC=<name>` or `EXEC <name>` references.
   Members are matched by filename stem case-insensitively.
3. `symbol_overrides` — a flat map of `SYMBOL → value` used when a
   PROC parameter is not supplied at the invocation site. Recorded
   verbatim in the profile under `symbolOverrides`.
4. `style_profile_path` — path to `target-repo-style-profile.json`
   produced by `scan-target-repo-patterns`. Not consumed structurally
   here, but its presence is recorded so downstream skills can chain.

## Workflow

Execute the steps in order. After each numbered step, write a
one-line checkpoint to the agent log so the run is resumable.

1. **Validate input.** Confirm every `jcl_paths` entry exists, is
   readable, ends with an accepted extension, and is not a directory.
   For each file, detect encoding: assume EBCDIC if any byte > 0x7F
   appears in the first 4 KiB and no UTF-8 BOM is present; otherwise
   ASCII/UTF-8. Convert EBCDIC (CP037) to UTF-8 before further
   processing. Checkpoint: `files=<n> encoding=<ascii|ebcdic>`.

2. **Normalize.** JCL records are fixed 80 columns. Strip cols 73–80
   (identification area). Join continuations: a line that ends inside
   parameter context with a trailing `,` and the next line starting
   `// ` (two slashes, then blank) is a continuation; concatenate
   into a single logical card. Preserve `lineMap[logicalCard] =
   [originalLine, ...]` for back-reference. Do **not** lowercase any
   token — JCL is case-sensitive in DSNs and DDnames.

3. **Tokenise cards.** Classify each logical card by its first
   non-`//` token:
   - `JOB` → job card.
   - `EXEC` → step card (`PGM=` or `PROC=` or bare procname).
   - `DD` → data definition.
   - `PROC` / `PEND` → in-stream PROC boundary.
   - `IF` / `THEN` / `ELSE` / `ENDIF` → conditional block.
   - `INCLUDE MEMBER=` → JCL include.
   - `JCLLIB ORDER=` → PROC search path addition.
   - `SET` → symbol assignment.
   - `OUTPUT` → SYSOUT definition.
   - `//*` → comment.
   - `//SYSIN DD *` (and `/*` terminator) → instream data block.

4. **Resolve PROCs (one level required, recursion best-effort).**
   For each `EXEC PROC=<name>` (or bare `EXEC <name>` that is not a
   load module), locate the PROC either (a) earlier in the same file
   between `PROC`/`PEND`, or (b) in `proc_dirs` (after applying any
   `JCLLIB ORDER=(...)` paths discovered in step 3). Substitute the
   PROC's symbolic parameters using, in priority order: explicit
   `name=value` on the invoking EXEC, prior `SET` cards in scope,
   `symbol_overrides`, then the PROC's own defaults. Record every
   unresolved PROC with `resolved: false` and warning
   `W-PROC-UNRESOLVED:<name>` — do **not** abort.

5. **Build the step list per job.** For each `JOB` card, walk its
   cards in source order and produce `steps[]`:
   `{ stepName, source: "inline|proc:<name>", program, cond, ifGuard,
   restart, ddStatements: [...] }`. A `procStep` (an EXEC inside a
   resolved PROC) is emitted with both the calling step name and the
   PROC's internal step name as `stepName: "<caller>.<procStep>"`.

6. **Extract DD facts.** For each `DD` card:
   - `ddName` (the symbol after `//`).
   - `dsn` (the value of `DSN=` or `DSNAME=`); flag GDG forms
     (`+1` / `-0` / `(+1)` / `(0)`) under `gdg: true` and capture
     the bias.
   - `disp` as a 3-tuple `[status, normal, abnormal]` filling
     defaults (`NEW`, `DELETE`, `DELETE`) when omitted.
   - `dcb`/`recfm`/`lrecl`/`blksize` when present (verbatim).
   - `dataClass`/`storClass`/`mgmtClass` (SMS) when present.
   - `sysout` true when `SYSOUT=` is set; capture class.
   - `instream` true for `DD *` or `DD DATA`; capture inline text
     line range from `lineMap` (do not copy the bytes).
   - `concat: true` when the DD has continuation DSNs without a
     DDname on the continuation cards.

7. **Extract control-flow facts.**
   - `cond`: parse `COND=(code,op[,stepName])` and the modern
     `IF (RC op n) THEN ... ELSE ... ENDIF` form. Normalise into
     `condition: { kind: "COND|IF", expr: "...", appliesTo:
     ["stepA","stepB"] }`.
   - `restart`: capture `RESTART=<stepName>` on the JOB card.
   - `chkpt`: capture any DD with `CHKPT=` or any `EXEC ...
     CHKPT=` parameter (rare but record).
   - `disposition`-driven flow is computed in step 8, not here.

8. **Compute dataset dependency edges.** Across the union of all
   jobs in the input:
   - For every step that has a DD with `disp[0] == "NEW"` or
     `disp[1] in {"CATLG","KEEP"}`, register the step as a
     **producer** of that DSN (resolve GDG generations to the
     base DSN plus bias).
   - For every step with a DD where `disp[0] in {"OLD","SHR","MOD"}`,
     register it as a **consumer**.
   - Emit `datasetEdges[]: { from: "<job>.<step>", to:
     "<job>.<step>", dsn: "...", via: "DSN", kind:
     "READ-AFTER-WRITE|MOD-AFTER-WRITE" }` for every producer →
     consumer pair, sorted by `(from, to, dsn)`.

9. **Compute metrics.**
   - `jobs.count`, `steps.count`, distinct `programs.count`.
   - Per job: `cyclomatic = 1 + count(COND) + count(IF) +
     count(ELSE) + count(restart-edges)`.
   - `unresolvedProcs`, `unresolvedIncludes`,
     `dynamicProgramRefs` (EXEC PGM=&SYMBOL).
   - `criticalPath`: longest acyclic path in the dataset-dependency
     DAG (Kahn topological order; break ties by `(from, to)`).

10. **Emit artifacts.** Write `job-flow.json` (schema below) and
    `job-flow.md` (≤ 80 lines) to the working directory. Both files
    MUST be deterministic for a given input: sort `jobs[]` by
    `jobName`, `steps[]` by source order within their job,
    `datasetEdges[]` by `(from, to, dsn)`, `programs[]` by name,
    `warnings[]` as plain strings ascending.

### Job-flow JSON schema (informative)

```jsonc
{
  "schemaVersion": "1.0",
  "sources": [
    { "path": "...", "encoding": "ascii|ebcdic", "sha256": "..." }
  ],
  "symbolOverrides": { "SYMBOL": "value" },
  "jobs": [
    {
      "jobName": "...",
      "class": "...|null",
      "msgClass": "...|null",
      "restart": "...|null",
      "jcllib": ["..."],
      "joblib": ["..."],
      "steps": [
        {
          "stepName": "...",
          "source": "inline|proc:<name>",
          "program": "...|null",
          "programDynamic": false,
          "steplib": ["..."],
          "cond": "...|null",
          "ifGuard": "...|null",
          "chkpt": "...|null",
          "ddStatements": [
            {
              "ddName": "...",
              "dsn": "...|null",
              "disp": ["NEW|OLD|SHR|MOD","CATLG|KEEP|DELETE|PASS",
                        "CATLG|KEEP|DELETE"],
              "gdg": false,
              "gdgBias": "+1|0|-1|null",
              "sysout": "A|*|...|null",
              "instream": false,
              "instreamLines": [0, 0],
              "concat": false,
              "dcb": { "recfm": "...", "lrecl": 0, "blksize": 0 },
              "sms": { "dataClass": "...", "storClass": "...",
                       "mgmtClass": "..." }
            }
          ]
        }
      ],
      "conditions": [
        { "kind": "COND|IF", "expr": "...", "appliesTo": ["..."] }
      ]
    }
  ],
  "programs": [
    { "name": "...", "calledFrom": ["<job>.<step>","..."],
      "dynamic": false }
  ],
  "datasetEdges": [
    { "from": "...", "to": "...", "dsn": "...",
      "via": "DSN", "kind": "READ-AFTER-WRITE|MOD-AFTER-WRITE" }
  ],
  "metrics": {
    "jobsCount": 0, "stepsCount": 0, "programsCount": 0,
    "cyclomaticPerJob": { "JOB1": 0 },
    "unresolvedProcs": 0, "unresolvedIncludes": 0,
    "dynamicProgramRefs": 0,
    "criticalPath": ["<job>.<step>", "..."]
  },
  "warnings": ["W-PROC-UNRESOLVED:PAYPROC", "..."],
  "chaining": { "styleProfileSeen": true, "profileSchemaVersion": "1.0" }
}
```

## Validation

The agent MUST run all checks before declaring success. Each check
either passes or appends a structured warning to
`job-flow.json#/warnings[]`. Hard-fail only on V1–V3.

- **V1 (hard).** Output file `job-flow.json` is valid JSON and
  conforms to the schema above (all required keys present, arrays
  present even when empty).
- **V2 (hard).** Every `datasetEdges[].from` and `.to` references an
  existing `<jobName>.<stepName>` produced in `jobs[].steps[]`.
  Every `programs[].calledFrom[]` likewise.
- **V3 (hard).** Every `jobs[].jobName` matches
  `/^[A-Z#@$][A-Z0-9#@$]{0,7}$/` (z/OS 8-char jobname rule
  <!-- VERIFY -->). Every step `program` (when not dynamic) matches
  `/^[A-Z#@$][A-Z0-9#@$]{0,7}$/` (load-module name rule
  <!-- VERIFY -->). Violations emit
  `W-NAME-TOO-LONG:<job|step>:<name>` AND fail.
- **V4.** Every `EXEC PROC=<name>` has either `source: "proc:<name>"`
  with a resolved step expansion, or warning
  `W-PROC-UNRESOLVED:<name>`.
- **V5.** Every `INCLUDE MEMBER=<m>` has been resolved or emits
  `W-INCLUDE-UNRESOLVED:<m>`.
- **V6.** Every `EXEC PGM=&<sym>` (dynamic) carries
  `programDynamic: true` AND emits `W-DYNAMIC-PROGRAM:<job>.<step>`.
- **V7.** `sources[].sha256` records the SHA-256 of the normalised
  source so downstream skills can detect drift.
- **V8.** `metrics.criticalPath` is a valid topological path through
  `datasetEdges[]` (no repeats, every consecutive pair appears as an
  edge). If `datasetEdges[]` is empty, `criticalPath = []`.
- **V9.** `job-flow.md` is ≤ 80 lines and references the JSON file
  path in its first line.

## Common pitfalls

- **EBCDIC source.** JCL pulled directly off a mainframe is usually
  CP037 (or CP1047). Run step 1's encoding check before tokenising
  or `//` will not even match.
- **Continuation rules.** A continued parameter ends with `,` and
  the next card starts with `// ` and a blank operation field. A
  card ending in a comma in the *comment* area is NOT a continuation
  — only commas in the parameter field count.
- **Symbolic substitution order.** Invocation `name=value` overrides
  PROC defaults; `SET` cards in scope override PROC defaults but are
  themselves overridden by invocation params. Do not collapse the
  precedence into a single dictionary — record source per value.
- **GDG generations.** `MY.GDG(+1)` is created NEW and is the
  *producer*; `MY.GDG(0)` is the current generation and is a
  *consumer*. Resolving both to the base DSN is what creates the
  dataset edge — do not key edges on the generation-qualified form.
- **DISP defaults.** Omitting the second/third positional defaults
  to `(NEW,DELETE,DELETE)`. Many step-skipping bugs in COBOL
  modernization come from missing the `DELETE` on normal completion;
  always fill defaults explicitly in the profile.
- **COND vs. IF.** They can coexist in the same job. Modern code
  often migrates `COND=ONLY` to `IF`. Record both forms verbatim in
  `condition.expr` so a human reviewer can audit.
- **JOBLIB vs. STEPLIB.** JOBLIB applies to every step in the job;
  STEPLIB only to its own step. STEPLIB overrides JOBLIB when both
  are present — record both, do not merge.
- **EXEC PGM=IEFBR14 / IDCAMS / SORT / IEBGENER.** These are utility
  programs, not application COBOL. Emit them in `programs[]` but
  mark `dynamic: false, utility: true` (extend the schema with a
  `utility` flag if your runtime needs the distinction; not in the
  base schema above).
- **Instream SYSIN.** The body between `DD *` and `/*` may contain
  control statements (e.g. for SORT, IDCAMS). Capture only the line
  range; downstream skills decide whether to slurp the bytes.
- **PROC recursion.** A PROC can EXEC another PROC. Step 4 mandates
  one-level resolution and best-effort beyond that; record the
  recursion depth in a warning `W-PROC-DEPTH:<depth>` when > 2.
- **Restart loops.** `RESTART=` jumping backward into an earlier
  step creates a cycle that is *not* a data-flow cycle. Keep
  `datasetEdges[]` acyclic; restart edges live only on the JOB card.

## Outputs

Written to the agent's current working directory:

1. `job-flow.json` — canonical orchestration profile (schema above).
   Consumed by every downstream modernization skill that cares
   about batch sequencing.
2. `job-flow.md` — human-readable summary: count of jobs / steps /
   programs, the critical path, top-5 most-consumed datasets, top-5
   producer→consumer chains, and any V4–V9 warnings.

Both files are idempotent: re-running the skill on unchanged inputs
MUST produce byte-identical output (sort + stable formatting).

## Chaining

Upstream (optional):

- `scan-target-repo-patterns` — produces `target-repo-style-profile.json`
  referenced by `chaining.styleProfileSeen` for downstream skills.

Downstream (typical):

- `analyze-cobol-program` — invoked once per distinct
  `programs[].name` (skipping utilities) to produce a program-level
  profile for each EXEC PGM= discovered here.
- `diagram-cobol-with-mermaid` — reads `jobs[].steps[]` and
  `datasetEdges[]` to render a job-flow Mermaid graph.
- `plan-strangler-fig-migration` — reads `datasetEdges[]` and
  `programs[].calledFrom[]` to slice the migration along
  dataset boundaries.
- `map-vsam-db2-to-jpa` — reads `jobs[].steps[].ddStatements[]` to
  enumerate VSAM datasets (organization inferred from cataloged
  metadata or downstream COBOL SELECTs).
- `generate-modernization-tests` — reads the critical path and
  dataset edges to size end-to-end characterisation tests.

