PHASE 4 — IMPLEMENTATION (TWO-PASS, CHECKPOINTED)

═══════════════════════════════════════════════════════════════════════
WHY CHECKPOINTS
═══════════════════════════════════════════════════════════════════════

Even small models can produce one file at a time reliably. They fail
when asked to produce many files in one response. So every checkpoint
here is SMALL on purpose (3–4 skeleton files OR 2–3 implemented files).

═══════════════════════════════════════════════════════════════════════
PASS A — SKELETONS (checkpointed, 3–4 files per checkpoint)
═══════════════════════════════════════════════════════════════════════

Trigger: user says `pass-a-plan`.

STEP A1 — PASS A PLAN (always first)

Read STATE/repo-profile.md and 03-mapping.md.
Count total artifacts to skeleton. Compute number of checkpoints:
total_files / 4  (round up; 3 files allowed for last checkpoint)
Produce a plan file:
STATE/conversions/<PROGRAM_NAME>/04a-skeleton-plan.md

Table:
| Checkpoint | Files (≤ 4) | Artifact types |

End chat with:
"Pass A plan: <N> skeleton checkpoints, <M> total files.
Reply `skeleton CP-01` to begin."

STOP.

STEP A2 — EXECUTE ONE SKELETON CHECKPOINT

Trigger: user says `skeleton CP-NN`.

For each file in this checkpoint (max 4):
- Open ONLY the canonical example from repo-profile.md for this
  artifact TYPE (one example per type, reused if same type repeats).
- Create the file at the target path with:
    - package, imports (structural only)
    - class/interface/record signature matching canonical style
    - field declarations
    - constructor / annotations
    - method signatures with Javadoc citing BR-### owned
    - method bodies: a SINGLE
      throw new UnsupportedOperationException("TODO BR-...");
      line. NO BUSINESS LOGIC.
- PAUSE for user accept in IntelliJ before next file.

After all files in CP-NN done, append to
STATE/conversions/<PROGRAM_NAME>/04a-skeleton-log.md
the rows:
| Checkpoint | File | Type | Owner BR-IDs | Created/Modified |

End chat with:
"Skeleton CP-NN done. Remaining: <list>.
Reply `skeleton CP-NN+1` or `pass-b-plan` if all skeletons done."

STOP.

═══════════════════════════════════════════════════════════════════════
PASS B — FILL BODIES (checkpointed, 2–3 files per checkpoint)
═══════════════════════════════════════════════════════════════════════

Trigger: user says `pass-b-plan`.

STEP B1 — PASS B PLAN (always first)

Read 03-mapping.md and 04a-skeleton-log.md.
Group skeleton files into Pass B checkpoints of EXACTLY 2–3 files,
preferring files that share a BR-### group so context stays cohesive.

Produce STATE/conversions/<PROGRAM_NAME>/04b-impl-plan.md:
| Checkpoint | Files (2–3) | BR-IDs | Slices needed |

End chat with:
"Pass B plan: <N> impl checkpoints.
Reply `impl CP-01` to begin."

STOP.

STEP B2 — EXECUTE ONE IMPL CHECKPOINT

Trigger: user says `impl CP-NN`.

PRE-FLIGHT for this checkpoint:
- Read STATE/repo-profile.md
- Read 03-mapping.md (mapping table only)
- Read ONLY the 02-rules-<SLICE_ID>.md files listed in the
  checkpoint plan (typically 1–2 slices)
- Open ONLY the skeleton files in this checkpoint (2–3)
- Open ONE canonical example per artifact type appearing here

EXECUTION (one file at a time, pausing after each):
1. Replace each `throw new UnsupportedOperationException` body
   with idiomatic Java 21 implementing the BR-### rules listed.
2. Use BigDecimal + explicit scale + RoundingMode for COMP-3
   (per 02-rules and repo-profile.md).
3. Add `// COBOL-ORIGIN: <paragraph>` near the first non-trivial
   block in each method.
4. Pause for user accept/reject in IntelliJ.

After all files in CP-NN done, append to
STATE/conversions/<PROGRAM_NAME>/04b-impl-log.md:
| Checkpoint | File | BR-IDs implemented | Deviations | VERIFY markers |

SELF-CHECK at end of checkpoint:
- List BR-IDs that were assigned to this checkpoint
- Confirm each has a real implementation (no remaining TODO body)
- If anything missing, STOP and ask user

End chat with:
"Impl CP-NN done. Remaining: <list>.
Reply `impl CP-NN+1` or `verify` if all impl checkpoints done."

STOP.

═══════════════════════════════════════════════════════════════════════
ABSOLUTE RULES (PHASE 4)
═══════════════════════════════════════════════════════════════════════

- 3–4 files per skeleton checkpoint. 2–3 files per impl checkpoint.
  Never exceed.
- One file edit at a time in IntelliJ; pause for accept/reject.
- Never run mvn/gradle without explicit user permission.
- Never read the whole COBOL again. Use 02-rules files as the source
  of truth for business logic.
- Never read more than ONE canonical example per artifact type per
  session.
- If context feels tight (~70% capacity), STOP early and tell the user
  to split the checkpoint.
- Never commit, push, or run git.