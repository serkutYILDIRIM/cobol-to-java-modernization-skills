PHASE 4 — IMPLEMENT THE JAVA CODE

PRE-FLIGHT:
- Read repo-profile.md, 01-analysis.md, 02-rules.md, 03-mapping.md.
- Phase 3 mapping must be approved by the user.

STEP A — IMPLEMENT one artifact at a time, in this order:
  1. DTO records / value objects
  2. Entities and repositories (and migration script if needed)
  3. Mappers (MapStruct or whichever the repo uses)
  4. Domain/Service classes (where business rules live)
  5. Controllers / endpoints / batch steps
  6. Exception handling additions
  7. Configuration properties / wiring

For EACH artifact:
  - Open the target file (or create it at the path from 03-mapping.md)
  - Write idiomatic code matching repo-profile.md exactly
  - Add Javadoc on each method that owns a BR-### rule:
      /**
       * Implements business rules: BR-003, BR-004.
       * Converted from COBOL paragraph: CALC-NET-PAY.
       */
  - Add `// COBOL-ORIGIN: <paragraph>` near non-trivial blocks
  - Use BigDecimal with explicit scale + RoundingMode for COMP-3 values
  - Preserve every in-scope BR-### rule. Never silently drop a rule.

STEP B — After EACH artifact, pause and let the user accept/reject
in IntelliJ. Do not race ahead.

STEP C — Maintain `STATE/conversions/<PROGRAM_NAME>/04-implementation-log.md`:
  - Files created (path)
  - Files modified (path + summary of change)
  - Rules implemented (BR-### → FQCN.method)
  - Deviations from the plan with justification
  - Any new `<!-- VERIFY -->` markers introduced

STEP D — Self-check: list any BR-### from 02-rules.md not yet
implemented. If any are missing without an OUT-OF-SCOPE marker,
implement them or ask the user.

STEP E — End chat with: "Implementation complete. Proceed to Phase 5
(tests)?" — STOP.

DO NOT commit. DO NOT push. DO NOT run git.
DO NOT run build commands without asking first.