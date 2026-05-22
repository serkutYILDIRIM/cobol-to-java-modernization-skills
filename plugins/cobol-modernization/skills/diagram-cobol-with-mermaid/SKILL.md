---
name: diagram-cobol-with-mermaid
description: |
  Renders deterministic Mermaid diagrams (flowchart, sequenceDiagram, classDiagram,
  erDiagram, stateDiagram-v2) from upstream JSON artifacts produced by
  `analyze-cobol-program` (`program-profile.json`), `extract-cobol-business-rules`
  (`business-rules.json`), and `map-mainframe-job-flow` (`job-flow.json`).
  USE when the user asks to "visualise", "draw", "diagram", "render a chart of",
  "show the call graph / job flow / paragraph flow / data model / state machine"
  of a COBOL program, copybook set, or JCL job, OR when a downstream skill
  (`plan-strangler-fig-migration`, `generate-modernization-tests`) needs an
  embeddable diagram for documentation. DO NOT USE for free-form architecture
  whiteboarding, for diagrams of Java-21 target code (use a dedicated Java
  diagrammer), for sequence traces that require runtime data, or when the
  upstream JSON artifact does not yet exist — run the upstream extractor first.
  This skill is read-only over its inputs, emits only `.mmd` / `.md` files, and
  must produce byte-identical output across reruns for the same input bytes.
---

## Purpose

Turn the structured JSON facts that other COBOL-modernization skills emit into
small, reviewable, **GitHub-renderable** Mermaid diagrams. Diagrams are scoped
(one concern per file), deterministic (sorted nodes/edges, stable IDs), and
size-capped so a reviewer can read each one without scrolling sideways.

Five diagram kinds are supported, each driven by one or more upstream artifacts:

| Diagram kind                 | Mermaid type        | Primary input                         | Optional inputs                              |
|------------------------------|---------------------|---------------------------------------|----------------------------------------------|
| Paragraph / PERFORM flow     | `flowchart TD`      | `program-profile.json`                | `business-rules.json` (rule badges)          |
| Static program call graph    | `flowchart LR`      | `program-profile.json` (`calls[]`)    | `job-flow.json` (entry points)               |
| Business-rule decision tree  | `flowchart TD`      | `business-rules.json`                 | `program-profile.json` (paragraph anchors)   |
| JCL job / step DAG           | `flowchart LR`      | `job-flow.json`                       | `program-profile.json` (program tooltips)    |
| Copybook ↔ table ER          | `erDiagram`         | `program-profile.json` (`dataItems`)  | `job-flow.json` (`datasetEdges[]`)           |
| Program lifecycle state      | `stateDiagram-v2`   | `business-rules.json` (FLAG-MUTATION) | `program-profile.json`                       |

## When to use / When not to use

**Use** when:
- The upstream JSON artifact(s) already exist on disk and the user wants a
  diagram for a PR, ADR, runbook, or Strangler-Fig migration document.
- A downstream skill needs an embeddable diagram (no external image host).

**Do not use** when:
- The upstream JSON has not been produced yet — chain the extractor first.
- The user wants a UML diagram of the **Java target** code (out of scope; use a
  Java-side diagrammer such as PlantUML from bytecode).
- The user wants a runtime sequence (call timings, thread interleavings); this
  skill is static-only.
- The diagram would exceed the size cap below — split or summarise instead.

## Inputs

Required (at least one):

- `program-profile.json` — schema 1.0, emitted by `analyze-cobol-program`.
- `business-rules.json` — schema 1.0, emitted by `extract-cobol-business-rules`.
- `job-flow.json` — schema 1.0, emitted by `map-mainframe-job-flow`.

Optional:

- `target-repo-style-profile.json` — emitted by `scan-target-repo-patterns`.
  Only `chaining.styleProfileSeen` is consulted; no styling is taken from it
  (Mermaid theming stays vanilla for portability).
- `options.yaml` — caller-supplied knobs (all optional, defaults shown):
  ```yaml
  diagrams:                # subset of supported kinds
    - paragraph-flow
    - call-graph
    - rule-tree
    - job-dag
    - data-er
    - state-machine
  maxNodesPerDiagram: 60   # hard cap; over → split or summarise
  maxEdgesPerDiagram: 120
  includeRuleBadges: true  # overlay BR-* ids onto paragraph flow
  includeLineNumbers: true # add "L123" to node tooltips
  direction:               # per-diagram override
    paragraph-flow: TD
    call-graph: LR
    job-dag: LR
  ```

## Workflow

Deterministic, numbered, with checkpoints. Stop at any failed checkpoint.

1. **Discover inputs.** Resolve absolute paths for every artifact present.
   Record their SHA-256 and `schemaVersion`. If none of the three required
   artifacts is present, FAIL with `E-NO-INPUT`.
2. **Validate schema versions.** Each artifact must declare
   `schemaVersion: "1.0"`. Mismatch → FAIL `E-SCHEMA-MISMATCH:<artifact>`.
3. **Load options.** Merge caller `options.yaml` over defaults (above). Reject
   unknown keys → FAIL `E-UNKNOWN-OPTION:<key>`.
4. **Select diagram set.** For each kind in `options.diagrams` that has its
   primary input available, mark it `selected`. Skip silently otherwise and
   emit warning `W-DIAGRAM-SKIPPED:<kind>:no-input`.
5. **Build node/edge tables (in-memory only).** For each selected diagram:
   - **paragraph-flow**: nodes = `paragraphs[]`; edges = `performs[]`
     (`from → to`, label = `THRU`/`TIMES`/`VARYING`/`UNTIL` where present).
     Branch nodes from `EVALUATE`/`IF` arms inside `business-rules.json`
     (type `BRANCHING`) become diamond shapes.
   - **call-graph**: nodes = current program + every `calls[].target`; edges
     labeled `STATIC`/`DYNAMIC`; dynamic edges use dashed arrows.
   - **rule-tree**: one subgraph per `groupId`; nodes = rule ids; edges from
     `trigger.head` arm-chain ordering by `priority`.
   - **job-dag**: nodes = `jobs[].steps[]`; edges from `datasetEdges[]`
     (`from → to` with `dsn` label) plus `cond`/`ifGuard` annotations on
     incoming step edges.
   - **data-er**: entities = unique top-level records in `dataItems[]` whose
     `usage` is `FILE`/`TABLE`/`COPY`; relationships from `datasetEdges[]`
     (READ → `||--o{`, WRITE → `}o--||`, BOTH → `||--||`).
   - **state-machine**: states = distinct values written to status/flag
     fields identified by `FLAG-MUTATION` rules; transitions = the rules
     themselves; initial state inferred from `VALUE` clause if present.
6. **Stable IDs.** Mermaid node ids MUST be `[A-Za-z_][A-Za-z0-9_]*`. Derive
   via `slug(name) + "_" + short_hash(name, startLine)` where `short_hash`
   is the first 6 hex chars of SHA-256 (lower-case). This guarantees
   collision-free, line-position-anchored, deterministic ids.
7. **Sort.** Within each diagram: nodes sorted by `(startLine, name)`; edges
   sorted by `(fromId, toId, label)`. This is the determinism contract.
8. **Cap & split.** If `nodes > maxNodesPerDiagram` or
   `edges > maxEdgesPerDiagram`, split by `groupId` (rule-tree),
   `paragraphs[].section` (paragraph-flow), `jobs[].jobName` (job-dag), or
   `dataItems[].copybook` (data-er). Each split file gets suffix
   `__part-NN.mmd` (zero-padded, ordered by split key).
9. **Render.** Emit one `.mmd` file per (kind, split) under
   `out/diagrams/`. Also emit `out/diagrams/INDEX.md` with a deterministic
   table-of-contents and one embedded Mermaid block per file (so GitHub
   renders them inline).
10. **Run Validation V1–V8 below.** Stop on any hard-fail; emit warnings
    otherwise. Append all warnings, sorted, to `INDEX.md` under a
    `## Warnings` section.

## Validation

Hard-fail (the skill must abort and not write partial output):

- **V1 — Mermaid syntax.** Each `.mmd` file must parse with a Mermaid
  parser (mermaid-cli `mmdc --parseOnly`, or `@mermaid-js/parser`).
  Failure → `E-MERMAID-PARSE:<file>:<line>`. <!-- VERIFY mmdc flag name -->
- **V2 — Node id charset.** Every node id matches
  `^[A-Za-z_][A-Za-z0-9_]{0,63}$`. Failure → `E-NODE-ID:<id>`.
- **V3 — Edge integrity.** Every edge endpoint exists as a node in the
  same `.mmd` file. Failure → `E-DANGLING-EDGE:<from>-><to>`.
- **V4 — Schema versions.** All inputs declare `schemaVersion: "1.0"`.

Warn-only (emit code into `warnings[]`, continue):

- **V5 — Size cap exceeded after split** → `W-OVERSIZE:<file>:<nodes>/<edges>`.
- **V6 — Empty diagram** (kind selected but 0 nodes after filtering) →
  `W-EMPTY:<kind>`. The file is still emitted with a `%% empty` comment so
  reviewers see the intentional gap.
- **V7 — Dynamic call without resolution** → `W-DYN-CALL:<caller>-><expr>`.
- **V8 — Unrenderable rule trigger** (e.g. `EVALUATE` with no `WHEN`) →
  `W-RULE-TRIGGER:<ruleId>`.

Determinism contract: rerunning the skill on the same input bytes must
produce byte-identical `.mmd` and `INDEX.md` files (UTF-8, LF line endings,
no trailing whitespace, single trailing newline).

## Common pitfalls

- **Using paragraph names as Mermaid ids.** COBOL allows hyphens (`9000-EXIT`)
  which Mermaid rejects. Always slug+hash (Workflow step 6).
- **Quoting `dsn` labels containing dots/parentheses.** Wrap in double quotes:
  `STEP010 -->|"PAY.MASTER(+1)"| STEP020`.
- **Mixing diagram directions.** Pick one per file; never use `direction LR`
  inside `flowchart TD` subgraphs unless every subgraph has it.
- **Forgetting `classDef` for dashed dynamic-call edges.** Define once at the
  top of the file; reuse via `class nodeId dyn`.
- **Embedding huge diagrams in PRs.** GitHub silently truncates Mermaid
  blocks over ~10 000 chars. Respect `maxNodesPerDiagram`. <!-- VERIFY -->
- **Re-sorting after splitting.** Sort BEFORE splitting; split preserves order.

## Outputs

Written under `out/diagrams/` (caller may rebase):

- `paragraph-flow[__part-NN].mmd`
- `call-graph[__part-NN].mmd`
- `rule-tree[__part-NN].mmd`
- `job-dag[__part-NN].mmd`
- `data-er[__part-NN].mmd`
- `state-machine[__part-NN].mmd`
- `INDEX.md` — TOC + embedded Mermaid blocks + `## Warnings` section +
  `## Provenance` table listing each input artifact with its SHA-256 and
  `schemaVersion`.

Each `.mmd` starts with a comment header:

```mermaid
%% diagram: paragraph-flow
%% source: program-profile.json sha256=<hex>
%% generator: diagram-cobol-with-mermaid v1.0
```

## Chaining

**Upstream (one or more required):**

- `analyze-cobol-program` → `program-profile.json`
- `extract-cobol-business-rules` → `business-rules.json`
- `map-mainframe-job-flow` → `job-flow.json`
- `scan-target-repo-patterns` → `target-repo-style-profile.json` (optional,
  only for `chaining.styleProfileSeen` provenance)

**Downstream (consumers of `.mmd` / `INDEX.md`):**

- `plan-strangler-fig-migration` — embeds `job-dag` and `call-graph` into
  the migration plan.
- `generate-modernization-tests` — uses `rule-tree` and `state-machine` to
  derive characterization-test scenarios.
- Human reviewers via PR descriptions and ADRs.

This skill never writes back into upstream artifacts and never mutates source.

