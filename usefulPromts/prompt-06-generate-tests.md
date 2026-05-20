PHASE 5 — GENERATE TESTS

PRE-FLIGHT:
- Read repo-profile.md and 04-implementation-log.md.

STEP A — For every BR-### rule implemented, create at least one
test that:
  - Lives in the test location/package convention from repo-profile.md
  - Uses the project's test stack (JUnit version, AssertJ, Mockito,
    Testcontainers, etc.)
  - Has a name encoding the rule: e.g.,
      shouldApplyHigherTaxBracket_whenSalaryAboveThreshold_BR003()
  - Includes representative inputs derived from COBOL test data
    (or asks the user for sample inputs if unclear)

STEP B — Add characterization tests for any computation that
involves COMP-3 / BigDecimal arithmetic — pin the EXACT expected
output to catch precision regressions.

STEP C — If the repo uses integration tests with Testcontainers
or @SpringBootTest, add one happy-path integration test for the
new endpoint or service entry point.

STEP D — Maintain `STATE/conversions/<PROGRAM_NAME>/05-test-log.md`
listing every test added and which BR-### it covers. Flag any
uncovered rule.

STEP E — End chat with a coverage matrix:
  | BR-ID | Implemented in | Test class | Test method |
and a final note: "Conversion of <PROGRAM_NAME> complete. Review
diffs in IntelliJ before committing."

DO NOT commit. DO NOT push. DO NOT run git.