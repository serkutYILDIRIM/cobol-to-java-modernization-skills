# AGENTS.md

This repository provides **Agent Skills** (per the
[agentskills.io](https://agentskills.io) standard) for COBOL → Java 21
modernization. It does not ship a runtime agent of its own — instead, the
skills are designed to be installed into existing coding agents:

- **Claude Code** (via `.claude-plugin/marketplace.json`)
- **GitHub Copilot CLI / Coding Agent** (via `.github/plugin/marketplace.json`)
- **Cursor** (via `.cursor-plugin/marketplace.json`)

## What an agent gets

After installing the `cobol-modernization` plugin, an agent gains 10
composable skills covering: repo discovery, COBOL parsing, business-rule
extraction, JCL job-flow mapping, Mermaid diagramming, copybook → record
conversion, VSAM/DB2 → JPA mapping, COBOL → Java 21 transpilation,
Strangler-Fig migration planning, and test generation.

## Composition pattern

```
scan-target-repo-patterns
        │
        ├─► analyze-cobol-program ─► extract-cobol-business-rules
        │                          └► diagram-cobol-with-mermaid
        ├─► map-mainframe-job-flow ─► diagram-cobol-with-mermaid
        ├─► convert-copybook-to-java-record
        ├─► map-vsam-db2-to-jpa
        └─► transpile-cobol-to-java21 ─► plan-strangler-fig-migration
                                       └► generate-modernization-tests
```

See [`README.md`](README.md) for the full skill catalog.

