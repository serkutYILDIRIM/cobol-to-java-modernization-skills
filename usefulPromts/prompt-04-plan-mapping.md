PHASE 3 — MAP COBOL → JAVA (PLAN ONLY, NO CODE)

PRE-FLIGHT:
- Read repo-profile.md, 01-analysis.md, 02-rules.md.
- All Phase 2 questions must be answered.

STEP A — Decide the placement of new code, strictly following
repo-profile.md. For each artifact you intend to create or modify,
produce a row:

  | Artifact | Type | Layer | Target path | New or modify? | Reason |

Types include: Controller, Service, DomainService, UseCase, Entity,
Repository, DTO (record), Mapper, ConfigProperties, ExceptionHandler,
Migration script, Unit test, Integration test.

STEP B — Map every COBOL construct to a Java home:

  | COBOL element | Java home | Notes |
  | PROCEDURE DIVISION main | <ServiceClass>.<method> | |
  | Paragraph X | private method or extracted class | |
  | Working-storage record | DTO record / Entity | |
  | COPYBOOK Y | shared record in package z | |
  | EXEC SQL Z | repository method or @Query | |
  | EVALUATE block | switch pattern matching / Strategy | |
  | File I/O | repository / batch step | |

STEP C — Map every BR-### rule from 02-rules.md to a concrete Java
method (FQCN + method name). Every rule must have exactly one owner
method. If a rule is intentionally out of scope (PARTIAL mode),
mark it `OUT-OF-SCOPE` with reason.

STEP D — Identify integration points with the existing repo
(call existing service? new endpoint? event publish?). List them
explicitly with the existing class names verified by reading the files.

STEP E — Risk register: list anything that could break existing code,
data, or behavior. Propose mitigations.

STEP F — Write `STATE/conversions/<PROGRAM_NAME>/03-mapping.md` and
end chat with: "Plan ready. Approve to proceed to Phase 4
(implementation)?" — STOP and wait for user approval.

DO NOT commit. DO NOT modify src/.