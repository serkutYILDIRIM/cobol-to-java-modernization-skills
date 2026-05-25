---
name: transpile-cobol-to-java21
description: |
  Transpiles a single COBOL program (already analysed and rule-extracted) into
  idiomatic Java 21 + Spring Boot 3.x source code, using the target repository's
  style profile, the copybook-mapping records, and the jpa-mapping entities as
  the canonical type system. Emits one orchestrator service per PROGRAM-ID, one
  package-private paragraph method per PERFORMable paragraph, a sealed result
  type per EVALUATE TRUE block, and a `transpile-report.json` sidecar that
  pins every emitted Java line back to (source.sha256, originalLine) for
  audit. USE WHEN the user has `program-profile.json` (schemaVersion 1.0) AND
  `business-rules.json` (schemaVersion 1.0) AND at least one
  `copybook-mapping.json` for every COPY member used by the program AND wants
  runnable Java 21 source, not pseudocode. DO NOT USE for: copybook-only
  conversion (use `convert-copybook-to-java-record`); JCL → workflow conversion
  (use `map-mainframe-job-flow` + `plan-strangler-fig-migration`); ER/flow
  diagrams (use `diagram-cobol-with-mermaid`); whole-portfolio batch transpile
  (run this skill once per PROGRAM-ID, the outputs are not aggregated here);
  or rewriting business rules — this skill preserves them verbatim, it does
  NOT refactor them.
---

## Purpose

Convert one COBOL program — as described by its `program-profile.json` (from
`analyze-cobol-program`) and `business-rules.json` (from
`extract-cobol-business-rules`) — into compilable Java 21 source that:

- preserves every business rule by ID (`BR-…-NNN`) as a method or branch,
- reuses the records from `copybook-mapping.json` and the entities from
  `jpa-mapping.json` as its type system (NO new POJOs invented here),
- conforms to the target repo's `target-repo-style-profile.json`
  (package layout, naming, exception handling, logging, DTO convention),
- emits a `transpile-report.json` sidecar so every Java line can be traced
  back to the source `(sha256, originalLine)` pair.

This is the bridge skill between COBOL analysis and the Strangler-Fig
migration plan: its output is what `plan-strangler-fig-migration` slices and
what `generate-modernization-tests` characterises.

## When to use / When not to use

USE WHEN:

- A single COBOL program has been fully profiled and rule-extracted.
- All copybooks COPYed by that program have a corresponding
  `copybook-mapping.json`.
- A `target-repo-style-profile.json` exists (from `scan-target-repo-patterns`);
  if absent, the skill falls back to a documented default and emits
  `W-NO-STYLE-PROFILE`.
- A `jpa-mapping.json` exists IF the profile reports `db2Tables[]` or
  `vsamDatasets[]`; if persistent data exists but the mapping is missing,
  the skill HARD-FAILS with `E-NO-JPA-MAPPING`.

DO NOT USE WHEN:

- The user only wants record types — use `convert-copybook-to-java-record`.
- The user wants a multi-program migration plan — use
  `plan-strangler-fig-migration` (this skill is its input, not its replacement).
- The COBOL source has drifted from the sha256 recorded in `program-profile.json`
  (the skill will hard-fail with `E-SOURCE-DRIFT`).
- The user wants the rules rewritten, simplified, or "improved" — this skill
  is a faithful transpiler, not a refactorer.

## Inputs

| Input                          | Required | Source skill                       |
| ------------------------------ | -------- | ---------------------------------- |
| `program_profile_path`         | yes      | `analyze-cobol-program`            |
| `business_rules_path`          | yes      | `extract-cobol-business-rules`     |
| `copybook_mapping_paths[]`     | yes      | `convert-copybook-to-java-record`  |
| `jpa_mapping_path`             | cond.    | `map-vsam-db2-to-jpa`              |
| `style_profile_path`           | opt.     | `scan-target-repo-patterns`        |
| `cobol_source_path`            | yes      | repo                               |
| `target_package`               | opt.     | overrides style profile            |
| `emit_main_method` (bool)      | opt.     | default `false`                    |
| `out_dir`                      | yes      | usually `out/java/`                |

The skill reads NO live database, NO mainframe, NO network. All inputs are
local files. Determinism is mandatory (R7).

## Workflow

Numbered, deterministic. Every step has a checkpoint the agent can verify
before proceeding.

1. **Load + integrity-check the upstream JSON.**
   - Parse `program-profile.json`, `business-rules.json`, every
     `copybook-mapping.json`, and (if present) `jpa-mapping.json`.
   - Re-compute SHA-256 of the normalised COBOL source and compare against
     `program-profile.source.sha256`.
   - Checkpoint: `schemaVersion == "1.0"` on every input; sha256 matches.
     Otherwise emit `E-SOURCE-DRIFT` or `E-SCHEMA-DRIFT` and STOP.

2. **Resolve the type system.**
   - Build a lookup `cobolName → JavaType` from:
     `copybook-mapping.records[].fields[]` (record fields),
     `copybook-mapping.records[]` (record classes),
     `jpa-mapping.entities[]` (entity classes).
   - On collision, prefer the JPA entity over the copybook record and emit
     `W-TYPE-PROMOTED-TO-ENTITY:<cobolName>`.
   - Checkpoint: every `dataItems.reads / writes` in `business-rules.json`
     resolves; unresolved names emit `W-FIELD-UNRESOLVED:<n>` and become
     `Object` typed locals (compilable but flagged).

3. **Derive the orchestrator class.**
   - Class name = `PascalCase(PROGRAM-ID)` + style-profile suffix
     (`Service` by default).
   - Package = `style_profile.packageLayout.servicesPackage`
     (fallback: `<groupId>.legacy.<programIdLower>`).
   - Constructor-inject every `JpaRepository` referenced by any rule plus a
     `Clock` if any rule reads CURRENT-DATE/TIME.
   - Mark `@Service` (Spring) + `@Transactional` (class-level) if at least
     one rule writes a JPA entity or calls EXEC SQL UPDATE/INSERT/DELETE.

4. **Emit one method per PERFORMable paragraph.**
   - Method name = `camelCase(paragraphName)`; visibility = package-private.
   - Order methods by `(startLine, name)` for byte-stable output.
   - The PROCEDURE DIVISION's first paragraph becomes the public entry method,
     named `run(<inputDto>)` (DTO type taken from the LINKAGE SECTION 01-level,
     mapped through copybook records).

5. **Emit business rules verbatim by ID.**
   - For each rule in `business-rules.json`, render a Java block guarded by a
     leading comment `// BR-…-NNN (<rule.type>)` and a trailing
     `/* end BR-…-NNN */` so audit tooling can extract a rule's Java span.
   - Rule-type → Java idiom mapping table:
     | Rule type        | Java 21 idiom                                         |
     | ---------------- | ----------------------------------------------------- |
     | CALCULATION      | `var x = a.add(b, MathContext.DECIMAL64);`            |
     | VALIDATION       | `if (!cond) throw new DomainValidationException(...)` |
     | BRANCHING        | `switch` pattern matching on a sealed result type     |
     | LOOKUP           | `repository.findById(...).orElseThrow(...)`           |
     | MAPPING          | `var dto = mapper.toDto(entity);` (MapStruct)         |
     | FLAG-MUTATION    | `state = State.SUSPENDED;` on a sealed enum/state     |
     | IO-EFFECT        | typed repository call inside the @Transactional scope |
     | ERROR-HANDLING   | `catch (SpecificException e)` + log + rethrow as 5xx  |

6. **Lower EVALUATE TRUE into pattern-matching `switch`.**
   - For each EVALUATE TRUE block in `program-profile.controlFlow.evaluates[]`,
     synthesise a sealed interface `<Paragraph>Outcome permits …` whose
     `permits` list mirrors the WHEN arms (one record per arm + one
     `OtherOutcome` for WHEN OTHER).
   - The Java method `switch`es over the sealed type with patterns
     (`case Approved a -> …`, `case Rejected(var reason) -> …`).
   - Determinism: arm order = textual WHEN order from the profile.

7. **Lower PERFORM VARYING / UNTIL / TIMES.**
   - `PERFORM VARYING I FROM 1 BY 1 UNTIL I > N` →
     `for (int i = 1; i <= n; i++) { … }`.
   - `PERFORM N TIMES` → `for (int i = 0; i < n; i++) { … }`.
   - `PERFORM … UNTIL cond` → `while (!cond) { … }` (loop-test BEFORE body
     unless profile marks `WITH TEST AFTER`, then `do { … } while (!cond);`).
   - PERFORM THRU is REJECTED with `E-PERFORM-THRU-UNSUPPORTED` (rationale:
     non-local control flow has no idiomatic Java 21 equivalent; the user
     must restructure the COBOL paragraph range before transpilation).

8. **Lower CALL.**
   - Static `CALL 'SUBPROG'` → `@Autowired` field of type `Subprog` +
     `subprog.run(...)`; the target class must already exist (or be planned)
     in the same Java module. Otherwise emit `W-CALLEE-NOT-FOUND:SUBPROG`.
   - Dynamic `CALL WS-PROG` → strategy lookup via a
     `Map<String, LegacyCallee>` bean; emits `W-DYNAMIC-CALL:<wsField>`.

9. **Lower I/O.**
   - VSAM READ/WRITE/REWRITE/DELETE → repository methods on the JPA entity
     declared in `jpa-mapping.json`. Sequential READ NEXT becomes
     `Streamable<T>` iteration; KEYED READ becomes `findById`.
   - EXEC SQL is delegated: if `jpa-mapping.json` flagged the SQL as
     "derivable", emit a Spring Data derived query; otherwise emit
     `@Query("…")` with the original SQL preserved as a `// EXEC SQL` comment
     directly above. Cursors → `Stream<T>` from the repository.

10. **Write outputs deterministically.**
    - Emit `.java` files under `out_dir/<package-as-dirs>/`. UTF-8, LF,
      single trailing newline. No timestamps in headers.
    - Emit `out_dir/transpile-report.json` (schemaVersion 1.0; schema below).
    - Sort `report.files[]` by `javaFile`; `report.rules[]` by `id`;
      `report.warnings[]` as strings.
    - Checkpoint: re-run with identical inputs MUST produce byte-identical
      output (CI gate; see Validation V6).

### `transpile-report.json` schema (locked, v1.0)

```jsonc
{
  "schemaVersion": "1.0",
  "source": { "path": "src/cobol/BILL010.cob", "sha256": "…" },
  "program": "BILL010",
  "targetPackage": "com.acme.billing.legacy.bill010",
  "files": [
    {
      "javaFile": "com/acme/billing/legacy/bill010/Bill010Service.java",
      "className": "Bill010Service",
      "kind": "service",                       // service|sealed|dto|exception
      "lineMap": [
        { "javaLine": 42, "cobolLine": 137, "ruleId": "BR-BILLING-007" }
      ]
    }
  ],
  "rules": [
    { "id": "BR-BILLING-007", "javaFile": "…", "javaLineRange": [40, 58] }
  ],
  "unresolvedFields": ["WS-LEGACY-FLAG"],
  "warnings": [
    "W-DYNAMIC-CALL:WS-NEXT-PROG",
    "W-FIELD-UNRESOLVED:WS-LEGACY-FLAG"
  ],
  "chaining": {
    "styleProfileSeen": true,
    "programProfileSchemaVersion": "1.0",
    "businessRulesSchemaVersion": "1.0",
    "jpaMappingSchemaVersion": "1.0"
  }
}
```

## Validation

Hard-fail = STOP and emit nothing under `out_dir/`. Warn-only = continue,
record code in `warnings[]`, and exit 0.

| Id  | Severity   | Check                                                                |
| --- | ---------- | -------------------------------------------------------------------- |
| V1  | hard-fail  | All input JSON parses and `schemaVersion == "1.0"`                   |
| V2  | hard-fail  | `source.sha256` of every input matches the actual file on disk       |
| V3  | hard-fail  | Every emitted `.java` parses under `--release 21` (no syntax errors) |
| V4  | hard-fail  | Every `business-rules.json` rule appears in `report.rules[]`         |
| V5  | hard-fail  | No PERFORM THRU survived → `E-PERFORM-THRU-UNSUPPORTED`              |
| V6  | hard-fail  | Re-run produces byte-identical files (determinism gate)              |
| V7  | hard-fail  | `report.lineMap` covers ≥ 95 % of non-blank Java lines               |
| V8  | warn-only  | `W-FIELD-UNRESOLVED:<n>` for each name without a Java type           |
| V9  | warn-only  | `W-DYNAMIC-CALL:<wsField>`                                           |
| V10 | warn-only  | `W-CALLEE-NOT-FOUND:<prog>`                                          |
| V11 | warn-only  | `W-NO-STYLE-PROFILE` (default fallback applied)                      |
| V12 | warn-only  | `W-TYPE-PROMOTED-TO-ENTITY:<n>`                                      |
| V13 | warn-only  | `W-SQL-OPAQUE:<stmtId>` (could not derive Spring Data query)         |

Hard-fail codes (alphabetical): `E-JPA-MAPPING-MISSING`,
`E-NO-COPYBOOK-FOR-COPY:<member>`, `E-NO-JPA-MAPPING`,
`E-PERFORM-THRU-UNSUPPORTED`, `E-SCHEMA-DRIFT`, `E-SOURCE-DRIFT`,
`E-UNRESOLVED-PARAGRAPH:<name>`.

## Common pitfalls

- **Inventing types.** Never synthesise a new POJO. If a cobol name has no
  Java type, emit `Object` + `W-FIELD-UNRESOLVED:<n>`. Inventing types
  breaks the audit chain back to the copybook.
- **Rewriting rules.** This skill is a transpiler, not a refactorer. The
  Java for `BR-…-NNN` must be a faithful 1:1 lowering, even if the COBOL
  is awkward. Refactoring belongs in a later, human-reviewed PR.
- **BigDecimal arithmetic.** Always pass an explicit `MathContext` or
  `RoundingMode`; never rely on default rounding. COMP-3 fields have
  declared scale in `copybook-mapping.json` — use it.
- **Encoding.** COBOL source is often EBCDIC (IBM-1047). Read it through
  the host-encoding declared in `copybook-mapping.source.hostEncoding`,
  then normalise to UTF-8 before hashing. <!-- VERIFY -->
- **88-level condition names.** Render them as `static boolean is*` helpers
  on the owning record (consistent with `convert-copybook-to-java-record`).
  Do NOT inline them as raw equality checks — the audit fails.
- **GO TO.** Reject with `E-PERFORM-THRU-UNSUPPORTED`'s sibling
  `E-GOTO-UNSUPPORTED` IF the GO TO targets a paragraph outside the
  current section. Same-section GO TO is lowered to `continue` against a
  synthesised labeled outer loop, with `W-GOTO-LOWERED:<label>`.
- **Determinism.** Sort every collection before emission. Never use
  `HashMap` iteration order or `Files.list(...)` without `.sorted()`.

## Outputs

Under `out_dir/`:

```
out/java/
  com/acme/billing/legacy/bill010/
    Bill010Service.java
    Bill010Outcome.java                 (sealed interface, if any EVALUATE)
    dto/
      Bill010Input.java                 (record, from LINKAGE SECTION)
      Bill010Output.java                (record, from LINKAGE SECTION)
    exception/
      DomainValidationException.java    (only if any VALIDATION rule)
  transpile-report.json
```

No `pom.xml`, no `application.yml`, no test sources — those are owned by
`scan-target-repo-patterns` and `generate-modernization-tests` respectively.

## Chaining

Upstream (required):

- `analyze-cobol-program` → `program-profile.json`
- `extract-cobol-business-rules` → `business-rules.json`
- `convert-copybook-to-java-record` → one `copybook-mapping.json` per COPY
  member used by the program

Upstream (conditional / optional):

- `map-vsam-db2-to-jpa` → `jpa-mapping.json` (REQUIRED if the profile
  reports any `db2Tables[]` or `vsamDatasets[]`)
- `scan-target-repo-patterns` → `target-repo-style-profile.json` (optional;
  fallback default is applied with `W-NO-STYLE-PROFILE`)

Downstream:

- `plan-strangler-fig-migration` slices `transpile-report.json` to schedule
  routing waves.
- `generate-modernization-tests` consumes `lineMap` + `rules[]` to
  generate characterisation tests pinned to each `BR-…-NNN`.
- `diagram-cobol-with-mermaid` may re-render call-graph diagrams against the
  emitted Java to verify topology preservation.

