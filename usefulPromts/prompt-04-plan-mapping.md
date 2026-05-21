PHASE 3 — MAPPING PLAN (CROSS-SLICE, BUT INCREMENTAL)

This phase produces ONE consolidated plan that covers all slices whose
rules have already been extracted. Run it ONCE after all relevant
02-rules-<SLICE_ID>.md files exist.

PRE-FLIGHT:
- Read STATE/repo-profile.md
- Read STATE/conversions/<PROGRAM_NAME>/01a-manifest.md
- Read ALL files matching STATE/conversions/<PROGRAM_NAME>/02-rules-*.md
- Do NOT read the COBOL source again.
- Do NOT semantic-scan the whole Java repo. Instead:
  * For each artifact TYPE you plan to create (Controller, Service,
    Entity, Repository, DTO, Mapper, ExceptionHandler, Test):
    - Identify ONE canonical example from repo-profile.md
      (the path listed under "see ... for canonical example").
    - Open ONLY that one file.
    - Use its style as the template.
  * If a type is missing from repo-profile.md, ASK the user to
    point at a canonical example.

PRODUCE exactly ONE file:

STATE/conversions/<PROGRAM_NAME>/03-mapping.md

Sections:

1. Artifact placement table
   | Artifact name | Type | Layer | Target path | New/Modify |
   Canonical example | BR-IDs owned |

2. Construct mapping (compact table, one row per COBOL construct)

3. Rule ownership matrix
   One row per BR-### → exactly one owner method (FQCN.method).
   PARTIAL out-of-scope rules: mark OUT-OF-SCOPE with reason.

4. Slice-to-implementation-batch grouping
   Group artifacts into IMPLEMENTATION BATCHES so Phase 4 can
   process them one batch per session. Rules of thumb:
  - One batch ≤ 5 artifacts
  - One batch should cover a coherent business sub-feature
  - DTOs and entities go in the FIRST batch; controllers last
    Output a table:
    | Batch ID | Artifacts | Estimated LOC | Dependencies on |

5. Integration points (verified existing classes by file path)

6. Risk register + mitigations

End chat with:
"Plan ready. <N> implementation batches proposed.
Approve to proceed to Phase 4 Pass A (skeletons)?"

STOP. DO NOT modify src/. DO NOT run git.