# cobol-to-java-modernization-skills

A curated set of **Agent Skills** for modernizing IBM Enterprise COBOL / CICS / IMS /
DB2 / VSAM mainframe workloads into idiomatic **Java 21 + Spring Boot 3.x**
microservices.

> **Status:** scaffolding (Phase 2). SKILL.md bodies and `eval.yaml` tests
> are produced in Phases 3–4.

---

## Why these skills?

Mainframe modernization is not a single transpile step — it is a *pipeline*
of discovery, analysis, mapping, planning, conversion, and verification.
Each skill in this repo encapsulates one well-bounded step in that pipeline
so that a coding agent (Claude Code, GitHub Copilot CLI, Cursor, etc.) can
compose them deterministically on real codebases.

The skills are organized as a single plugin: **`cobol-modernization`**.

---

## Skills

| # | Skill ID | Category | One-liner |
|---|----------|----------|-----------|
| 1 | [`scan-target-repo-patterns`](plugins/cobol-modernization/skills/scan-target-repo-patterns/SKILL.md) | Discovery | Inventory a target repo's COBOL/JCL/copybook/DB2/VSAM assets and conventions. |
| 2 | [`analyze-cobol-program`](plugins/cobol-modernization/skills/analyze-cobol-program/SKILL.md) | Analysis | Parse a COBOL program into divisions, sections, paragraphs, data items, and control flow. |
| 3 | [`extract-cobol-business-rules`](plugins/cobol-modernization/skills/extract-cobol-business-rules/SKILL.md) | Analysis | Distill business rules from `EVALUATE`, `IF`, and `PERFORM` constructs into a rule catalog. |
| 4 | [`map-mainframe-job-flow`](plugins/cobol-modernization/skills/map-mainframe-job-flow/SKILL.md) | Analysis | Trace JCL → PROC → program → dataset flow into a job-step dependency graph. |
| 5 | [`diagram-cobol-with-mermaid`](plugins/cobol-modernization/skills/diagram-cobol-with-mermaid/SKILL.md) | Visualization | Render program control flow, call graphs, and job flows as Mermaid diagrams. |
| 6 | [`convert-copybook-to-java-record`](plugins/cobol-modernization/skills/convert-copybook-to-java-record/SKILL.md) | Conversion | Convert COBOL copybooks (PIC, COMP-3, REDEFINES, OCCURS) into Java 21 records. |
| 7 | [`map-vsam-db2-to-jpa`](plugins/cobol-modernization/skills/map-vsam-db2-to-jpa/SKILL.md) | Conversion | Map VSAM KSDS/ESDS and DB2 DDL to JPA entities + Spring Data repositories. |
| 8 | [`transpile-cobol-to-java21`](plugins/cobol-modernization/skills/transpile-cobol-to-java21/SKILL.md) | Conversion | Translate COBOL procedure-division logic into idiomatic Java 21 + Spring Boot services. |
| 9 | [`plan-strangler-fig-migration`](plugins/cobol-modernization/skills/plan-strangler-fig-migration/SKILL.md) | Planning | Produce an incremental Strangler-Fig migration plan with seams and rollback points. |
| 10 | [`generate-modernization-tests`](plugins/cobol-modernization/skills/generate-modernization-tests/SKILL.md) | Verification | Generate characterization, JUnit 5 + AssertJ, ArchUnit, and Testcontainers tests. |

Pipeline entry points: `scan-target-repo-patterns`, `analyze-cobol-program`,
`map-mainframe-job-flow`. Terminal step: `generate-modernization-tests`.

---

## Install

### Claude Code

```bash
# from the repo root, or from a clone path
claude plugin install ./plugins/cobol-modernization   # <!-- VERIFY exact CLI -->
```

Or, via the marketplace manifest:

```bash
claude marketplace add ./.claude-plugin/marketplace.json   # <!-- VERIFY -->
```

### GitHub Copilot CLI

```bash
gh copilot extension install ./plugins/cobol-modernization   # <!-- VERIFY -->
```

Or reference `.github/plugin/marketplace.json` from your Copilot
configuration.

### Cursor

```bash
cursor plugin install ./plugins/cobol-modernization   # <!-- VERIFY -->
```

Or point Cursor at `.cursor-plugin/marketplace.json`.

> The exact CLI verbs for each host are evolving. Verify against the host's
> current documentation; the manifest files in this repo follow the
> agentskills.io conventions.

---

## Local development & validation

```bash
# Lint markdown
npx markdownlint-cli2 "**/*.md"

# Validate plugin & marketplace manifests + reference-domain allowlist
# (runs the same checks as .github/workflows/validate.yml)
./eng/validate.sh   # to be added in Phase 5
```

When authoring skills, follow [`CONTRIBUTING.md`](CONTRIBUTING.md) and the
[skill authoring guide](docs/skill-authoring-guide.md).

---

## License

[MIT](LICENSE)

