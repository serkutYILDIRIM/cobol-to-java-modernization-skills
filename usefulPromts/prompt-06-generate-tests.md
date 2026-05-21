PHASE 5 — TESTS (BATCHED, ONE BATCH PER SESSION)

Trigger: "Run Phase 5 for batch <BATCH_ID>".

PRE-FLIGHT:
- Read STATE/repo-profile.md
- Read STATE/conversions/<PROGRAM_NAME>/03-mapping.md
- Read ONLY STATE/conversions/<PROGRAM_NAME>/04b-impl-log-<BATCH_ID>.md
  (if missing, read 04b-impl-log.md and filter to this batch)
- Read ONLY the implementation files listed in that log
- Open ONE canonical test example from repo-profile.md
  (for unit tests AND, if needed, for integration tests).

EXECUTION:
For each BR-### implemented in this batch, create at least one test:
- Lives in the test location/package from repo-profile.md
- Uses the project's test stack only
- Name encodes the rule: shouldDoX_whenY_BR_S1_003()
- Inputs derived from COBOL test data or asked from the user

Add characterization tests for COMP-3 / BigDecimal computations,
pinning exact expected outputs.

If this batch includes a controller / endpoint, add ONE happy-path
integration test (only if the repo already uses @SpringBootTest /
Testcontainers — confirmed via repo-profile.md).

Pause for user accept/reject after each test file.

Append to STATE/conversions/<PROGRAM_NAME>/05-test-log-<BATCH_ID>.md:
| BR-ID | Test class | Test method | Notes |

End chat with:
"Tests for batch <BATCH_ID> complete. Coverage matrix above.
Remaining batches: <list>."

═══════════════════════════════════════════════════════════════════════
ABSOLUTE RULES
═══════════════════════════════════════════════════════════════════════

- Never run mvn/gradle without asking.
- Never commit, push, or run git.
- Never read all impl-logs — only the one for this batch.
- One test file at a time, pause for accept/reject.