PHASE 6 — VERIFICATION (COBOL vs JAVA, CHECKPOINTED)

Goal: confirm that the Java implementation faithfully covers every
in-scope COBOL business rule. Run AFTER Phase 4 and Phase 5 are complete.

═══════════════════════════════════════════════════════════════════════
STEP 1 — VERIFICATION PLAN
═══════════════════════════════════════════════════════════════════════

Trigger: user says `verify-plan`.

PRE-FLIGHT:
- Read STATE/repo-profile.md
- Read 03-mapping.md
- Read ALL 02-rules-*.md files (rules only; cheap)
- Read 04b-impl-log.md (file list only)

Group all BR-### rules into VERIFICATION CHECKPOINTS of 5 rules each.
Cluster rules by Java file when possible so context per checkpoint
stays focused.

Produce STATE/conversions/<PROGRAM_NAME>/06-verify-plan.md:
  | Checkpoint | BR-IDs (≤ 5) | Java files involved |

End chat with:
  "Verification plan ready: <N> checkpoints.
   Reply `verify CP-01` to begin."

STOP.

═══════════════════════════════════════════════════════════════════════
STEP 2 — EXECUTE ONE VERIFY CHECKPOINT
═══════════════════════════════════════════════════════════════════════

Trigger: user says `verify CP-NN`.

PRE-FLIGHT:
- Read ONLY the 02-rules-*.md sections for the BR-IDs in this
  checkpoint (grep by BR-ID, do not load whole rules files if large).
- Open ONLY the Java files listed in this checkpoint.
- (Optional) Open the COBOL line ranges referenced by the BR-IDs
  if needed for arithmetic verification.

For each BR-### in this checkpoint, produce a verification row:

  | BR-ID | COBOL intent (1 line) | Java location (FQCN.method) |
    Coverage (FULL/PARTIAL/MISSING) | Numeric precision OK? |
    Notes / discrepancies |

For any FULL row with arithmetic, manually trace one representative
input through both sides (COBOL pseudocode → Java code) and confirm
identical output. Show the trace in the notes column.

For PARTIAL or MISSING rows, propose a concrete fix:
  - Which file to edit
  - Which code block to add/change
  - Whether a test is also missing

Append findings to:
  STATE/conversions/<PROGRAM_NAME>/06-verify-log.md

End chat with:
  "Verify CP-NN done. Issues found: <count>.
   Remaining checkpoints: <list>.
   Reply `verify CP-NN+1` or `verify-summary` if all done."

STOP.

═══════════════════════════════════════════════════════════════════════
STEP 3 — FINAL SUMMARY
═══════════════════════════════════════════════════════════════════════

Trigger: user says `verify-summary`.

Read all 06-verify-log.md entries. Produce a single section at the
top of that file titled `## Final Verification Summary`:

  - Total BR-IDs in scope
  - FULL coverage count
  - PARTIAL coverage count + list
  - MISSING coverage count + list
  - Recommended remediation order (highest-risk first)
  - Open VERIFY markers anywhere in the impl logs

End chat with:
  "Verification complete. <X> issues need remediation.
   Review 06-verify-log.md before commit."

═══════════════════════════════════════════════════════════════════════
ABSOLUTE RULES
═══════════════════════════════════════════════════════════════════════

- 5 BR-IDs per checkpoint, max.
- Never load the whole COBOL again unless arithmetic verification
  needs a specific line range.
- Never re-read all 02-rules-*.md files if the BR-IDs in scope are
  only in 1–2 of them.
- Never modify src/ during verification — only report. Remediation
  is a separate Phase 4 Pass B mini-checkpoint chosen by the user.
- Never commit, push, or run git.