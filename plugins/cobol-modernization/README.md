# Plugin: `cobol-modernization`

Agent skills for modernizing IBM Enterprise COBOL / CICS / IMS / DB2 / VSAM
mainframe workloads into idiomatic **Java 21 + Spring Boot 3.x**
microservices.

## Skills

| # | Skill | Description |
|---|-------|-------------|
| 1 | [`scan-target-repo-patterns`](skills/scan-target-repo-patterns/SKILL.md) | Inventory a target repo's COBOL/JCL/copybook/DB2/VSAM assets, naming conventions, and build wiring. |
| 2 | [`analyze-cobol-program`](skills/analyze-cobol-program/SKILL.md) | Parse a COBOL program into divisions, sections, paragraphs, data items, and control flow. |
| 3 | [`extract-cobol-business-rules`](skills/extract-cobol-business-rules/SKILL.md) | Distill business rules from `EVALUATE`, `IF`, and `PERFORM` constructs into a structured rule catalog. |
| 4 | [`map-mainframe-job-flow`](skills/map-mainframe-job-flow/SKILL.md) | Trace JCL → PROC → program → dataset flow into a job-step dependency graph. |
| 5 | [`diagram-cobol-with-mermaid`](skills/diagram-cobol-with-mermaid/SKILL.md) | Render program control flow, call graphs, and job flows as Mermaid diagrams. |
| 6 | [`convert-copybook-to-java-record`](skills/convert-copybook-to-java-record/SKILL.md) | Convert copybooks (PIC, COMP-3, REDEFINES, OCCURS DEPENDING ON) into Java 21 records. |
| 7 | [`map-vsam-db2-to-jpa`](skills/map-vsam-db2-to-jpa/SKILL.md) | Map VSAM KSDS/ESDS and DB2 DDL to JPA entities + Spring Data repositories. |
| 8 | [`transpile-cobol-to-java21`](skills/transpile-cobol-to-java21/SKILL.md) | Translate COBOL procedure-division logic into idiomatic Java 21 + Spring Boot services. |
| 9 | [`plan-strangler-fig-migration`](skills/plan-strangler-fig-migration/SKILL.md) | Produce an incremental Strangler-Fig migration plan with seams and rollback points. |
| 10 | [`generate-modernization-tests`](skills/generate-modernization-tests/SKILL.md) | Generate characterization, JUnit 5 + AssertJ, ArchUnit, and Testcontainers tests. |

## Install

See the top-level [README.md](../../README.md#install) for host-specific
installation snippets (Claude Code, Copilot CLI, Cursor).

## Layout

```
plugins/cobol-modernization/
├── plugin.json          # plugin manifest
├── README.md            # this file
└── skills/
    └── <skill-id>/
        ├── SKILL.md     # frontmatter + body (≤ 500 lines)
        ├── scripts/     # optional progressive disclosure
        ├── references/  # optional deep-dive material
        └── assets/      # optional fixtures/diagrams
```

## Contributing

See the top-level [`CONTRIBUTING.md`](../../CONTRIBUTING.md).

