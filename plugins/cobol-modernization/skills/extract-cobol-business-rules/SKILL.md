---
name: extract-cobol-business-rules
description: |
  Reads the `program-profile.json` emitted by `analyze-cobol-program`
  together with the original COBOL source (and any resolved copybooks)
  and derives a deterministic catalog of **business rules** — discrete,
  human-readable statements of WHAT the program decides, calculates,
  validates, or persists, with verbatim source citations for every
  rule. Each rule has a stable ID, a type (CALCULATION, VALIDATION,
  BRANCHING, LOOKUP, MAPPING, FLAG-MUTATION, IO-EFFECT,
  ERROR-HANDLING), a plain-language statement, the COBOL predicates
  and expressions it was lifted from, the data items it reads/writes,
  and a confidence score. USE this skill after `analyze-cobol-program`
  has succeeded, whenever you need a reviewable business specification
  before transpiling, writing characterisation tests, or drafting a
  target Java domain model. DO NOT use it: (a) to parse COBOL from
  scratch — run `analyze-cobol-program` first and pass its profile;
  (b) to translate rules into Java — chain into
  `transpile-cobol-to-java21`; (c) to render flowcharts — chain into
  `diagram-cobol-with-mermaid`; (d) to extract job-flow / step-level
  rules across many programs — use `map-mainframe-job-flow`. Inputs:
  `program-profile.json` plus the original `*.cob|*.cbl|*.cobol` file
  (and optional `copybook_dirs` and `domain_glossary.yaml`). Outputs:
  `business-rules.json` (machine-readable catalog) and
  `business-rules.md` (human review doc) in the working directory.
---

## Purpose

Lift the implicit business logic of a single COBOL program into an
explicit, reviewable, citation-linked rule catalog. The catalog is the
**source of truth** that domain experts validate and that downstream
skills (transpilation, test generation, JPA mapping) consume — so the
target Java code never re-derives meaning from the COBOL syntax twice.

Each rule answers three questions:

1. **What** does the program decide or compute? (plain-language
   statement, not COBOL.)
2. **When** does it apply? (trigger paragraph + predicate.)
3. **Where** does it live in the source? (file path + line range,
   verbatim snippet.)

## When to use / When not to use

Use when:

- You already have a valid `program-profile.json` from
  `analyze-cobol-program` for the program in question.
- You need a reviewable specification document before a domain expert
  signs off the migration of that program.
- You need stable rule IDs to attach characterisation tests to.

Do **not** use when:

- The profile is missing or its `schemaVersion` is not `1.0` — re-run
  the analyser first.
- You want a cross-program / cross-job rule inventory — that is
  `map-mainframe-job-flow` plus a higher-level aggregation step.
- You only need a structural map (paragraph graph, file usage) —
  `analyze-cobol-program` already covers that.

## Inputs

Required:

1. `program_profile_path` — path to `program-profile.json`
   (output of `analyze-cobol-program`, `schemaVersion: "1.0"`).
2. `program_source_path` — path to the original COBOL source the
   profile was generated from. The skill verifies that the file's
   sha256 matches `source.sha256` in the profile and aborts on drift.

Optional:

3. `copybook_dirs` — directories searched to resolve copybook fields
   referenced by rules. Used only to enrich `dataItems[]` with
   PIC / level info; missing copybooks degrade the field info but
   never block extraction.
4. `domain_glossary_path` — YAML file mapping raw data-item names
   (e.g. `CM-PLAN-CODE`) to business terms (`customerPlanCode`,
   `Customer Plan Code`). When present, the rule statements use the
   glossary's human form. When absent, statements fall back to the
   COBOL identifier and a `W-NO-GLOSSARY` warning is emitted.
5. `style_profile_path` — `target-repo-style-profile.json` from
   `scan-target-repo-patterns`. Not consumed structurally here; its
   presence is recorded in `chaining.styleProfileSeen` so downstream
   skills can chain.

## Workflow

Execute in order. Emit a one-line checkpoint after each step.

1. **Load and verify the profile.** Parse `program-profile.json`. If
   `schemaVersion != "1.0"`, abort with `E-PROFILE-SCHEMA`. Re-hash
   `program_source_path` and compare to `source.sha256`; on mismatch
   abort with `E-SOURCE-DRIFT`. Checkpoint:
   `profile=ok programId=<...>`.

2. **Load optional helpers.** Read the domain glossary into a map
   `cobolName -> { javaName, displayName, description }`. Index the
   `copybook_dirs` shallowly: build a map `fieldName -> { pic, level,
   sourceFile }` for every elementary item found. Missing files are
   logged, not fatal.

3. **Compute paragraph walk order.** Start at the program entry
   paragraph (first entry of `procedure.paragraphs[]` sorted by
   `startLine`). Do a depth-first traversal over `performEdges[]`,
   visiting each paragraph at most once, deterministic on the
   `(startLine, name)` sort key. Paragraphs unreachable from the
   entry are appended at the end in source order and tagged
   `reachable: false` on every rule lifted from them.

4. **Segment each paragraph into statements.** Re-read the source
   slice `[startLine..endLine]` and split into top-level COBOL
   sentences. Recognise these statement kinds (one rule candidate
   per occurrence unless merged in step 6):
   - `IF ... [ELSE ...] END-IF`               → BRANCHING / VALIDATION
   - `EVALUATE ... WHEN ... [WHEN OTHER] END-EVALUATE` → one rule per
     `WHEN` arm (a `WHEN OTHER` arm becomes an explicit default rule)
   - `COMPUTE`, `ADD`, `SUBTRACT`, `MULTIPLY`, `DIVIDE` → CALCULATION
   - `MOVE <literal> TO <flag>` or `SET <88-name> TO TRUE`
                                                → FLAG-MUTATION
   - `MOVE <field> TO <field>`                 → MAPPING
   - `PERFORM ... UNTIL` / `PERFORM ... VARYING` → BRANCHING (loop)
   - `READ`, `WRITE`, `REWRITE`, `DELETE`, `START`, `OPEN`, `CLOSE`
                                                → IO-EFFECT
   - `EXEC SQL ... END-EXEC`                   → LOOKUP (SELECT/FETCH)
     or IO-EFFECT (INSERT/UPDATE/DELETE/COMMIT/ROLLBACK)
   - `EXEC CICS ... END-EXEC`                  → IO-EFFECT
   - `CALL '<sub>' USING ...`                  → IO-EFFECT (delegated)
   - `IF SQLCODE`, `AT END`, `INVALID KEY`, `ON SIZE ERROR`,
     `NOT ON SIZE ERROR`                       → ERROR-HANDLING
   - `GOBACK`, `STOP RUN`, `EXIT PROGRAM`      → not a rule; recorded
                                                  in `programExit`

5. **Lift each candidate into a rule object.** Populate:
   - `id` — `BR-<PARAGRAPH-NAME>-<NNN>` where `<NNN>` is a
     zero-padded sequence within the paragraph (`001`, `002`, ...).
     Must match `/^BR-[A-Z0-9-]+-\d{3}$/`.
   - `paragraph`, `section`, `startLine`, `endLine`.
   - `type` — one of the eight types above.
   - `statement` — one-sentence plain-language description, written
     in present-tense indicative ("When the customer plan is `PRO`,
     the base amount is computed as `usage × 0.10 + 9.99`."). Use
     glossary `displayName`s when available.
   - `trigger` — the enclosing predicate(s) expressed as a normalised
     boolean expression (COBOL operators rewritten:
     `=`→`==`, `NOT =`→`!=`, `AND/OR`→`&&/||`, `NOT`→`!`). For
     unconditional statements, `trigger: "ALWAYS"`.
   - `expression` — for CALCULATION rules, the COBOL RHS rewritten in
     infix form with original identifiers (no glossary substitution).
   - `dataItems` — `{ reads: [...], writes: [...] }` resolved against
     copybook + WORKING-STORAGE; each entry `{ name, pic, level,
     source: "WORKING-STORAGE|LINKAGE|FILE|COPY:<member>" }`.
   - `domainTerms` — glossary `displayName`s used in `statement`.
   - `sourceSnippet` — verbatim COBOL lines, leading whitespace
     preserved, no line numbers embedded.
   - `confidence` — see step 8.
   - `reachable` — boolean from step 3.

6. **Merge co-located arms.** All `WHEN` arms inside the same
   `EVALUATE TRUE` share a `groupId` (`G-<PARAGRAPH>-<seq>`) and the
   same `trigger` head (`"EVALUATE TRUE"`); the arm predicate goes
   into each rule's `trigger.arm`. A `WHEN OTHER` arm becomes a rule
   with `trigger.arm: "DEFAULT"` and `priority: 999`.

7. **Resolve names.** For every identifier in `dataItems`,
   `trigger`, and `expression`, attempt resolution in this order:
   (a) WORKING-STORAGE / LINKAGE / FILE SECTION of the profile,
   (b) any resolved copybook, (c) domain glossary. Unresolved
   identifiers stay as-written and add `W-FIELD-UNRESOLVED:<name>`
   to `warnings[]` (deduplicated).

8. **Score confidence.** Start at `1.00`, subtract:
   - `-0.20` if any identifier in the rule is unresolved.
   - `-0.20` if `trigger` contains a dynamic CALL or computed
     identifier the analyser flagged.
   - `-0.10` if the paragraph has `maxNestingDepth >= 3` in the
     profile (deep nesting reduces extraction certainty).
   - `-0.10` if `programExit` happens inside the same paragraph
     before the rule's `endLine` (rule may be unreachable).
   - `-0.10` if no glossary entry exists for any data item in the
     rule.
   Floor at `0.10`. Emit `W-LOW-CONFIDENCE:<id>` for any
   `confidence < 0.50`.

9. **Emit artifacts.** Write `business-rules.json` (schema below)
   and `business-rules.md` (≤ 120 lines) to the working directory.
   Both files MUST be byte-deterministic for the same inputs:
   sort `rules[]` by `(startLine, id)`; sort `warnings[]` by string.

### `business-rules.json` schema (informative)

```jsonc
{
  "schemaVersion": "1.0",
  "source": {
    "profilePath":  "...",
    "programPath":  "...",
    "programId":    "...",
    "sourceSha256": "..."          // copied from profile, asserted
  },
  "summary": {
    "ruleCount":   0,
    "byType":      { "CALCULATION": 0, "VALIDATION": 0,
                     "BRANCHING": 0,   "LOOKUP": 0,
                     "MAPPING": 0,     "FLAG-MUTATION": 0,
                     "IO-EFFECT": 0,   "ERROR-HANDLING": 0 },
    "unreachableRules": 0
  },
  "rules": [
    {
      "id":             "BR-2100-COMPUTE-BILL-003",
      "groupId":        "G-2100-COMPUTE-BILL-001",
      "paragraph":      "2100-COMPUTE-BILL",
      "section":        "2100-COMPUTE-BILL",
      "startLine":      102,
      "endLine":        103,
      "type":           "CALCULATION",
      "statement":      "When the customer plan is 'PRO', the base
                         amount is set to usage × 0.10 + 9.99.",
      "trigger":        { "head": "EVALUATE TRUE",
                          "arm":  "CM-PLAN-CODE == 'PRO'",
                          "priority": 3 },
      "expression":     "WS-BASE-AMT = (CM-USAGE * 0.10) + 9.99",
      "dataItems":      { "reads":  [ { "name": "CM-PLAN-CODE",
                                        "pic": "X(03)",
                                        "level": 5,
                                        "source": "COPY:CUSTREC" },
                                      { "name": "CM-USAGE",
                                        "pic": "S9(7)V99 COMP-3",
                                        "level": 5,
                                        "source": "COPY:CUSTREC" } ],
                          "writes": [ { "name": "WS-BASE-AMT",
                                        "pic": "S9(7)V99 COMP-3",
                                        "level": 5,
                                        "source": "WORKING-STORAGE" } ] },
      "domainTerms":    ["Customer Plan Code", "Usage Units",
                         "Base Amount"],
      "sourceSnippet":  "WHEN CM-PLAN-CODE = 'PRO'\n   COMPUTE WS-BASE-AMT = (CM-USAGE * 0.10) + 9.99",
      "confidence":     0.90,
      "reachable":      true
    }
  ],
  "programExit": { "kind": "GOBACK", "paragraph": "0000-MAIN",
                   "line": 64 },
  "warnings":   [ "W-NO-GLOSSARY",
                  "W-FIELD-UNRESOLVED:CM-USAGE" ],
  "chaining":   { "styleProfileSeen": false,
                  "profileSchemaVersion": "1.0" }
}
```

## Validation

Hard-fail on V1–V3. V4+ append to `warnings[]`.

- **V1 (hard).** `business-rules.json` parses as JSON and contains
  all required top-level keys (`schemaVersion`, `source`, `summary`,
  `rules`, `programExit`, `warnings`, `chaining`).
- **V2 (hard).** Every `rules[].id` is unique, matches
  `/^BR-[A-Z0-9-]+-\d{3}$/`, and its `paragraph` exists in the
  profile's `procedure.paragraphs[]`. Every `(startLine, endLine)`
  falls inside that paragraph's range from the profile.
- **V3 (hard).** `source.sourceSha256` equals the profile's
  `source.sha256` AND the freshly computed sha256 of
  `program_source_path` (i.e. the profile is current).
- **V4.** Every identifier in `dataItems` has at least one of
  `pic` set or a `W-FIELD-UNRESOLVED:<name>` warning emitted.
- **V5.** Every rule with `type == CALCULATION` has a non-empty
  `expression`; every rule with `type == BRANCHING` or `VALIDATION`
  has a non-empty `trigger.arm` (or `trigger == "ALWAYS"` only for
  unconditional MAPPING / IO-EFFECT / FLAG-MUTATION).
- **V6.** `summary.ruleCount == rules.length` and each
  `summary.byType[T]` equals the count of rules of type `T`.
- **V7.** For each `EVALUATE TRUE` group, exactly one rule has
  `trigger.arm == "DEFAULT"` if and only if the COBOL source had a
  `WHEN OTHER` arm.
- **V8.** `business-rules.md` is ≤ 120 lines and references the
  JSON path in its first line.

## Common pitfalls

- **Re-parsing COBOL.** Do not. The profile already enumerates
  paragraphs, edges, and SQL/CICS blocks; this skill only re-reads
  the source for verbatim snippets. Re-parsing risks divergence from
  `analyze-cobol-program`.
- **`EVALUATE TRUE` is decision-table-like.** Each `WHEN` is a
  separate rule with a shared group; the `WHEN OTHER` arm is the
  default fallback and MUST appear as an explicit rule, not be
  swallowed. Domain experts reviewing the document need to see it.
- **`IF SQLCODE`.** This is an error-handling rule, NOT a generic
  validation. Tag `type: "ERROR-HANDLING"` and tie it to the
  immediately preceding `EXEC SQL` rule via `groupId`.
- **88-level condition names.** `IF WS-EOF` references an 88-level
  defined as `88 WS-EOF VALUE 'Y'.`; the rule statement should say
  "when end-of-file is reached", not "when WS-EOF-FLAG = 'Y'".
- **Implicit `ELSE`.** A missing `ELSE` arm in an `IF` is not an
  error, but if the THEN arm mutates a flag the agent must record
  the implicit "otherwise leave the flag unchanged" as a comment in
  the rule's `statement`, not as a separate rule.
- **`PERFORM ... THRU`.** Treat as a single BRANCHING rule whose
  `expression` lists the inclusive paragraph range; do NOT generate
  one rule per traversed paragraph (those already have their own
  rules from their own statements).
- **`COMPUTE WS-X ROUNDED ON SIZE ERROR`.** Lift the CALCULATION
  and the `ON SIZE ERROR` arm as two rules sharing a `groupId`
  (CALCULATION + ERROR-HANDLING). The `ROUNDED` clause belongs to
  the CALCULATION rule's `statement` ("rounded to scale 2") because
  it affects business semantics.
- **Dynamic CALL.** `CALL WS-PGM-NAME USING ...` produces an
  IO-EFFECT rule whose `statement` says "delegates to a dynamically
  resolved sub-program <WS-PGM-NAME>"; do not invent a target.
- **Determinism.** Glossary keys are matched case-insensitively but
  emitted using the glossary's canonical case; without this the JSON
  output drifts between runs on case-insensitive filesystems.

## Outputs

Written to the agent's current working directory:

1. `business-rules.json` — canonical rule catalog (schema above).
   Consumed by `transpile-cobol-to-java21`,
   `generate-modernization-tests`, and `plan-strangler-fig-migration`.
2. `business-rules.md` — review document grouped by paragraph: for
   each paragraph, list its rules in source order with id, type,
   confidence, plain-language statement, and a 1–4 line source
   snippet. Ends with a "Warnings" section.

Both files are idempotent: re-running with unchanged inputs MUST
produce byte-identical output.

## Chaining

Upstream (required):

- `analyze-cobol-program` — produces the `program-profile.json`
  consumed here. Re-run it whenever the source changes; this skill
  hard-fails on sha256 drift.

Upstream (optional):

- `scan-target-repo-patterns` — recorded in
  `chaining.styleProfileSeen` for downstream skills.

Downstream (typical):

- `transpile-cobol-to-java21` — consumes `rules[]` to generate
  domain services whose methods mirror rule IDs (`@RuleId("BR-...")`).
- `generate-modernization-tests` — generates one characterisation
  test per `rules[].id`, asserting input → output equivalence.
- `plan-strangler-fig-migration` — uses `summary.byType` and rule
  groupings to prioritise migration slices.
- `diagram-cobol-with-mermaid` — can overlay rule IDs onto the
  PERFORM graph for review.
- `map-vsam-db2-to-jpa` — uses LOOKUP rules to derive JPQL/criteria
  queries and read-only repositories.

