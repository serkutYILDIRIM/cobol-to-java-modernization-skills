---
name: convert-copybook-to-java-record
description: |
  Converts one Enterprise COBOL copybook (a `.cpy`, `.cbl`, or `.cob` file
  containing only DATA-DIVISION-style 01-level group items, no PROCEDURE
  DIVISION) into one or more idiomatic Java 21 `record` types plus a
  deterministic `copybook-mapping.json` artifact that documents every
  field-level mapping (COBOL name + PICTURE + USAGE → Java name + Java
  type + scale + nullability + EBCDIC byte offset). Handles fixed-format
  and free-format copybooks; resolves `OCCURS` to `List<T>`,
  `OCCURS DEPENDING ON` to a bounded list with a runtime size guard,
  `REDEFINES` to a Java 21 sealed interface with one record per variant,
  `COMP-3` / `PACKED-DECIMAL` to `BigDecimal` with explicit `scale`,
  `COMP` / `BINARY` to `int` / `long` / `BigInteger` by digit count, and
  `PIC X(n)` / `PIC A(n)` to `String` (trailing-space semantics recorded
  in the mapping). USE this skill when you have a copybook (typically
  surfaced by `analyze-cobol-program#/data/copybooks[]`) and need
  immutable Java DTOs that downstream skills (`map-vsam-db2-to-jpa`,
  `transpile-cobol-to-java21`, `generate-modernization-tests`) can
  consume. DO NOT use it for: (a) a full COBOL program — use
  `analyze-cobol-program`; (b) a VSAM/DB2 access mapping — use
  `map-vsam-db2-to-jpa`; (c) generating JPA entities (records are
  domain DTOs, not `@Entity` types); (d) inferring business rules from
  data items — chain into `extract-cobol-business-rules`. Inputs: one
  copybook file path, optional REPLACING pairs, optional
  `target-repo-style-profile.json`, optional `program-profile.json`.
  Outputs: one `.java` file per top-level 01 (plus sealed-variant files
  for REDEFINES), and `copybook-mapping.json`.
---

## Purpose

Turn a COBOL copybook into a deterministic, idiomatic Java 21 record
graph that is safe to import into a Spring Boot 3.x module without
re-parsing COBOL, while preserving the byte-level layout in a sidecar
JSON so that wire-format readers/writers can be generated later (by
`transpile-cobol-to-java21` or hand-written) without ambiguity.

The skill is intentionally **type-only**: it emits immutable records
and one JSON mapping file. It does **not** emit JPA entities,
serialisation code, or test fixtures — those are downstream skills'
jobs.

## When to use / When not to use

Use when:

- `analyze-cobol-program` has surfaced one or more `data.copybooks[]`
  entries with `resolved: true` and you need Java DTOs for them.
- You are starting a Strangler-Fig slice and want a stable,
  immutable Java type that mirrors a copybook record exactly.
- You need a sidecar JSON that records EBCDIC byte offsets and lengths
  so a downstream codec can read/write the original fixed-length
  record format.

Do **not** use when:

- The file contains a `PROCEDURE DIVISION` (it is a program, not a
  copybook) — use `analyze-cobol-program`.
- You need a JPA `@Entity` (records are immutable; JPA needs a
  no-arg constructor and mutable fields) — use `map-vsam-db2-to-jpa`
  and treat the record as the API DTO over the entity.
- You need to derive validation rules or business logic from the
  copybook — use `extract-cobol-business-rules`.
- The copybook is a CICS BMS map or DB2 DCLGEN — those have their own
  conventions and are out of scope for v1.0.

## Inputs

Required:

1. `copybook_path` — absolute path to one copybook file (`.cpy`,
   `.cob`, `.cbl`, `.cobol`). Must contain only level numbers 01–49
   (plus 66, 77, 88) — no `PROCEDURE DIVISION`.

Optional:

2. `replacing` — array of `["==tag==", "==value=="]` pairs to apply
   to the copybook before parsing (matches Enterprise COBOL
   `COPY ... REPLACING ==X== BY ==Y==` semantics).
3. `style_profile_path` — `target-repo-style-profile.json` emitted by
   `scan-target-repo-patterns`. When present, the skill reads
   `javaVersion`, `packageLayout`, `namingConventions`, and
   `dtoConvention` to align package name, file header, and Javadoc
   style with the target repository.
4. `program_profile_path` — `program-profile.json` emitted by
   `analyze-cobol-program` for the program that COPYs this copybook.
   Used only to enrich Javadoc with a back-reference and to pick the
   right `REPLACING` pairs from `data.copybooks[].replacing`.
5. `target_package` — explicit Java package override. Wins over the
   style profile if both are present.
6. `host_encoding` — `ibm-1047` (default), `ibm-037`, or `utf-8`.
   Affects byte-length calculations only.

## Workflow

Execute the steps in order. After each numbered step, write a one-line
checkpoint to the agent log so the run is resumable.

1. **Validate input.** Confirm `copybook_path` exists, is readable,
   and ends with an accepted extension. Reject any file whose
   normalised content contains `PROCEDURE DIVISION`. Detect source
   format (fixed cols 7–72 vs. free) via the same column-7 heuristic
   as `analyze-cobol-program`. Checkpoint: `format=<fixed|free>`.

2. **Normalise.** Strip sequence numbers (cols 1–6) and identification
   area (cols 73–80) for fixed format. Join continuation lines (`-`
   in column 7) into the previous logical line. Preserve a side map
   `lineMap[normalisedLine] = originalLine`.

3. **Apply REPLACING.** If `replacing` is provided, perform exact
   token replacement of each `==tag==` with the corresponding
   `==value==` over the normalised text. Record the applied pairs
   in `copybook.replacingApplied[]`. Do **not** apply partial-token
   matches; copybook REPLACING is whole-token.

4. **Parse data items.** Use an open-source COBOL parser such as
   ProLeap or Koopa <!-- VERIFY --> in DATA-DIVISION-only mode. If
   unavailable, fall back to a deterministic level-number tokeniser
   that recognises: `level-number data-name [REDEFINES x] [OCCURS n
   [TIMES] [DEPENDING ON y]] [PIC[TURE] is <pic>] [USAGE [IS] <u>]
   [SIGN [IS] LEADING|TRAILING [SEPARATE]] [VALUE [IS] <lit>]
   [BLANK WHEN ZERO] [JUSTIFIED RIGHT] [SYNCHRONIZED]`. Skip 66 and
   77 with a warning (see V5). Treat 88-level items as
   `conditionNames[]` attached to the parent.

5. **Build the field tree.** For each 01-level group, build a tree
   where each node carries: level, COBOL name, picture, usage,
   `occurs` info, `redefines` info, `valueLiteral`, 88-level
   condition names, original line, and computed `byteOffset` and
   `byteLength` (in `host_encoding`). Compute offsets in source
   order; for `REDEFINES`, the variant starts at the offset of the
   redefined target.

6. **Resolve Java types.** Apply the following mapping table
   deterministically (first match wins):

   | COBOL                                              | Java 21 type                |
   |----------------------------------------------------|-----------------------------|
   | `PIC X(n)` / `PIC A(n)` / alphanumeric             | `String` (length `n`)       |
   | `PIC 9(n)` DISPLAY, `n ≤ 9`                        | `int`                       |
   | `PIC 9(n)` DISPLAY, `10 ≤ n ≤ 18`                  | `long`                      |
   | `PIC 9(n)` DISPLAY, `n ≥ 19`                       | `BigInteger`                |
   | `PIC S9(n)` COMP / BINARY, `n ≤ 4`                 | `short`                     |
   | `PIC S9(n)` COMP / BINARY, `5 ≤ n ≤ 9`             | `int`                       |
   | `PIC S9(n)` COMP / BINARY, `10 ≤ n ≤ 18`           | `long`                      |
   | `PIC S9(n)V9(m)` COMP-3 / PACKED-DECIMAL           | `BigDecimal` scale=`m`      |
   | `PIC 9(n)V9(m)` DISPLAY                            | `BigDecimal` scale=`m`      |
   | `PIC ...` edited (Z, ., $, /, B, CR, DB, +, -)     | `String` (display-only)     |
   | group item with children                           | nested `record`             |
   | `OCCURS n TIMES` on field `f`                      | `List<T>` of size `n`       |
   | `OCCURS n TO m TIMES DEPENDING ON v`               | `List<T>` size `≤ m`        |
   | `REDEFINES`                                        | sealed-interface variant    |
   | `USAGE POINTER` / `INDEX` / `PROCEDURE-POINTER`    | (skipped + `W-USAGE-DROP`)  |

   Numeric edited pictures keep the edit mask in
   `fields[].displayFormat` for downstream formatters.

7. **Resolve Java names.** Convert each COBOL name to UpperCamelCase
   for record types and lowerCamelCase for record components, using
   the rules from `namingConventions` in the style profile when
   present. Default rules: split on `-`, lowercase, capitalise each
   token; if the resulting identifier is a Java reserved word,
   suffix with `_` and emit `W-NAME-RESERVED:<original>`. Names that
   collide within the same record get a numeric suffix `_2`, `_3`, …
   and emit `W-NAME-COLLISION:<javaName>`.

8. **Plan REDEFINES.** For each set of items that share a redefined
   target, emit a Java 21 **sealed interface** `XxxVariant` and one
   `record` per variant implementing it. The first declared item
   (the redefined target itself) is `XxxVariantPrimary`; each
   `REDEFINES` sibling is `XxxVariantRedef<i>` (`i` is 1-based in
   declaration order). The parent record's component becomes
   `XxxVariant variant` (non-null). Record-level Javadoc lists each
   variant's discriminator (if any 88-level condition name on a
   sibling indicates how to pick it).

9. **Emit Java files.** For each top-level 01 group, emit one
   `<RecordName>.java` plus one file per sealed interface and per
   variant under
   `<javaPackage-as-dirs>/`. Each file:
   - has the header comment block from the style profile (or the
     default header in `references/example-output.md`),
   - declares `package <javaPackage>;` and minimal imports
     (`java.math.BigDecimal`, `java.math.BigInteger`,
     `java.util.List`, `java.util.Objects` only when actually used),
   - declares the `record` (or `sealed interface ... permits ...`),
   - has a `static` factory method `of(...)` only when the record
     has 88-level condition names (to expose them as `static boolean
     isXxx(value)` helpers — never as constructor logic),
   - is UTF-8, LF, single trailing newline.

10. **Emit `copybook-mapping.json`.** See the schema below. Both the
    Java files and the JSON file MUST be deterministic for a given
    input: arrays sorted by `(byteOffset, javaName)`, maps with
    sorted keys, no timestamps anywhere in the output.

### `copybook-mapping.json` schema (informative)

```jsonc
{
  "schemaVersion": "1.0",
  "source": {
    "path": "...",
    "format": "fixed|free",
    "sha256": "...",
    "hostEncoding": "ibm-1047|ibm-037|utf-8"
  },
  "copybook": {
    "member": "...",
    "replacingApplied": [ ["==tag==","==value=="] ]
  },
  "javaPackage": "com.acme.billing.cobol",
  "records": [
    {
      "javaName": "BillRecord",
      "javaFile": "com/acme/billing/cobol/BillRecord.java",
      "fromCobolName": "BILL-REC",
      "fromStartLine": 12,
      "byteLength": 256,
      "fields": [
        {
          "javaName": "customerId",
          "javaType": "long",
          "fromCobolName": "BILL-CUST-ID",
          "level": 5,
          "picture": "S9(10) COMP",
          "usage": "BINARY",
          "byteOffset": 0,
          "byteLength": 8,
          "scale": 0,
          "signed": true,
          "nullable": false,
          "occurs": null,
          "redefines": null,
          "conditionNames": [],
          "originalLine": 14
        }
      ],
      "conditionNames": []
    }
  ],
  "variants": [
    {
      "sealedInterface": "AddressVariant",
      "permits": [
        "AddressVariantPrimary",
        "AddressVariantRedef1"
      ],
      "redefinedField": "BILL-ADDR-AREA",
      "javaFile": "com/acme/billing/cobol/AddressVariant.java"
    }
  ],
  "warnings": [ "W-USAGE-DROP:BILL-PTR", "W-NAME-RESERVED:CLASS" ],
  "chaining": {
    "styleProfileSeen": true,
    "profileSchemaVersion": "1.0",
    "programProfileSeen": true
  }
}
```

## Validation

Run all checks before declaring success. V1–V4 are hard-fail; V5–V10
append a code to `warnings[]` (sorted as strings).

- **V1 (hard).** `copybook-mapping.json` is valid JSON and conforms to
  the schema above (all required keys present, arrays present even
  when empty).
- **V2 (hard).** Every emitted `.java` file parses with a Java 21
  parser (`javac --release 21 -Xprefer:source -proc:none -d /tmp/out`
  or equivalent in-process parser). No file may reference a type or
  package that is not declared/imported.
- **V3 (hard).** Sum of `fields[].byteLength` (excluding `redefines`
  siblings) equals `records[].byteLength` for every top-level record.
  REDEFINES siblings must have `byteLength` ≤ redefined target.
- **V4 (hard).** `source.sha256` of the normalised, post-REPLACING
  copybook is recorded so downstream skills can detect drift. Every
  `records[].fromStartLine` and `fields[].originalLine` references an
  existing line in the original (pre-normalisation) copybook via
  `lineMap`.
- **V5.** Level-66 (`RENAMES`) and level-77 standalone items are not
  supported in v1.0; emit `W-LEVEL-66:<name>` or `W-LEVEL-77:<name>`
  and skip them. The mapping is still emitted for the rest.
- **V6.** `USAGE POINTER` / `INDEX` / `PROCEDURE-POINTER` /
  `OBJECT REFERENCE` fields are dropped with `W-USAGE-DROP:<name>`.
- **V7.** `OCCURS DEPENDING ON <var>` where `<var>` is not declared
  inside the same 01 group emits
  `W-ODO-EXTERNAL:<field>:<var>` (the mapping still uses `List<T>`
  with `≤ max` size; the runtime guard becomes the consumer's job).
- **V8.** Java-side name collisions and reserved-word clashes emit
  `W-NAME-COLLISION:<javaName>` or `W-NAME-RESERVED:<original>`.
- **V9.** Numeric edited pictures (`Z`, `.`, `$`, `B`, `/`, `CR`,
  `DB`, `+`, `-`) are emitted as `String` with a non-null
  `displayFormat`. Emit `W-EDITED-AS-STRING:<name>` once per edited
  field.
- **V10.** `records[]` is non-empty. If the copybook contains no
  01-level items (e.g. only 88-level toggles), hard-fail with
  `E-NO-01-LEVEL` instead of emitting an empty array.

## Common pitfalls

- **REDEFINES with smaller variant.** A `REDEFINES` sibling may be
  shorter than the redefined target; do **not** pad it. The sealed
  interface contract is "one of these layouts occupies the same
  bytes"; padding is the codec's job.
- **OCCURS DEPENDING ON.** The maximum size determines the Java
  `List<T>` upper bound recorded in `byteLength`; the *actual* size
  is a runtime concern. Never collapse ODO to a fixed-size array.
- **COMP vs. COMP-3 vs. DISPLAY.** Same PIC, totally different byte
  width. Always read `USAGE` before sizing a numeric field:
  COMP-3 byte length = `ceil((digits + 1) / 2)`; COMP byte length
  = 2 for ≤4 digits, 4 for ≤9, 8 for ≤18.
- **Signed DISPLAY with SIGN LEADING SEPARATE.** Adds one byte to
  `byteLength`; do not forget it.
- **Trailing spaces in `PIC X(n)`.** Record `nullable: false` and
  document in Javadoc that the COBOL convention is space-padded;
  the Java consumer is responsible for `.stripTrailing()` if it
  wants logical equality. Do **not** auto-trim at construction.
- **Reserved words.** `class`, `record`, `enum`, `interface`,
  `switch`, `yield`, `var`, `record` (yes — Java 16+ context),
  `sealed`, `permits`. Suffix with `_` and warn.
- **Group items with no children of their own data.** A pure group
  item that just nests becomes a nested record; do not flatten it,
  or downstream diff tools lose the structure.
- **88-level condition names.** Do **not** generate enums — generate
  `public static boolean is<Name>(<type> value)` helpers on the
  containing record. Enums lose the open-world semantics of 88s.
- **Picture parsing.** `PIC S9(7)V99 COMP-3` and `PIC S9(7)V9(2)
  COMP-3` are the same; normalise both to `digits=9, scale=2`
  before the type table lookup.

## Outputs

Written to the agent's current working directory:

1. One or more `.java` files under `<javaPackage-as-dirs>/`:
   - One top-level `record` per 01-level group item.
   - One nested `record` per multi-child group child.
   - One `sealed interface` + one `record` per variant for every
     `REDEFINES` family.
2. `copybook-mapping.json` — canonical field-level mapping (schema
   above). Consumed by `map-vsam-db2-to-jpa`,
   `transpile-cobol-to-java21`, and `generate-modernization-tests`.

Both Java files and the JSON file are idempotent: re-running the
skill on an unchanged copybook MUST produce byte-identical output
(sort + stable formatting + no timestamps).

## Chaining

Upstream (optional but recommended):

- `scan-target-repo-patterns` — supplies `javaPackage`,
  `namingConventions`, and file-header template via
  `target-repo-style-profile.json`. Without it, defaults are used
  and `chaining.styleProfileSeen` is `false`.
- `analyze-cobol-program` — supplies `data.copybooks[]` so the
  caller knows *which* copybooks to convert and which REPLACING
  pairs to pass in.

Downstream (typical):

- `map-vsam-db2-to-jpa` — reads `copybook-mapping.json` to derive
  JPA `@Entity` classes whose columns mirror the record components,
  one entity per VSAM file or DB2 table that uses this copybook.
- `transpile-cobol-to-java21` — imports the emitted records as
  domain DTOs; references `copybook-mapping.json#/records[]` so
  generated code uses the exact Java names.
- `generate-modernization-tests` — reads `byteOffset` / `byteLength`
  to build round-trip codec tests (EBCDIC bytes → record → EBCDIC
  bytes).

