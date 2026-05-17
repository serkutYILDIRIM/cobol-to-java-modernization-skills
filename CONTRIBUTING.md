# Contributing

Thanks for your interest in improving the `cobol-to-java-modernization-skills`
repository. This document mirrors the structure of
[`dotnet/skills/CONTRIBUTING.md`](https://github.com/dotnet/skills/blob/main/CONTRIBUTING.md)
and adapts it to the COBOL → Java 21 domain.

## Code ownership

The `.github/CODEOWNERS` file lists the reviewers for each path. All pull
requests require approval from at least one owner of every touched path.

## Repository layout

```
.
├── plugins/
│   └── cobol-modernization/
│       ├── plugin.json
│       ├── README.md
│       └── skills/
│           └── <skill-id>/
│               ├── SKILL.md
│               ├── scripts/        # optional, progressive disclosure
│               ├── references/     # optional, deep-dive material
│               └── assets/         # optional, fixtures/diagrams
├── tests/
│   └── cobol-modernization/
│       └── <skill-id>/eval.yaml
├── .claude-plugin/marketplace.json
├── .cursor-plugin/marketplace.json
├── .github/plugin/marketplace.json
├── docs/
├── eng/
└── _prompts/                       # author tooling (gitignored content optional)
```

## Plugin organization

This repo currently ships a **single plugin**: `cobol-modernization`.

- One plugin = one cohesive capability area.
- A plugin bundles skills that are typically composed together by an agent.
- Add new plugins (e.g., `pl1-modernization`) as siblings of
  `cobol-modernization`. Each must have its own `plugin.json` and `README.md`.

## Skill checklist

Before opening a PR for a new or updated skill, verify:

- [ ] Folder path is `plugins/cobol-modernization/skills/<skill-id>/`.
- [ ] `<skill-id>` is kebab-case and starts with an action verb.
- [ ] `SKILL.md` frontmatter contains **only** `name` and `description`.
- [ ] `description` embeds both "when to use" and "when NOT to use" hints
      so the runtime can route without loading the body.
- [ ] `SKILL.md` body is **≤ 500 lines**. If it exceeds, split into
      `scripts/`, `references/`, or `assets/` and link from `SKILL.md`
      (progressive disclosure).
- [ ] COBOL examples use realistic constructs (PIC, COMP-3, REDEFINES,
      OCCURS DEPENDING ON, EVALUATE, PERFORM VARYING, COPY ... REPLACING,
      EXEC SQL, EXEC CICS). No toy "Hello World" COBOL.
- [ ] Java examples are idiomatic Java 21 + Spring Boot 3.x (records,
      sealed types, pattern matching for switch, virtual threads,
      `Optional`, `Stream`).
- [ ] No invented vendor names, version numbers, or URLs (see "Security &
      no-hallucination" below).
- [ ] A matching `tests/cobol-modernization/<skill-id>/eval.yaml` exists.

## Skill naming

- kebab-case, lead with an action verb.
- Match an existing skill family if possible (`analyze-*`, `extract-*`,
  `map-*`, `diagram-*`, `convert-*`, `transpile-*`, `plan-*`,
  `generate-*`, `scan-*`).
- Keep the noun phrase short and specific
  (`convert-copybook-to-java-record`, not `convert-stuff`).

## Recommended SKILL.md sections

Inside the body (after frontmatter), use this order:

1. **Purpose** — one paragraph; what problem this skill solves.
2. **When to use / When NOT to use** — bulleted lists.
3. **Inputs** — required and optional inputs, with examples.
4. **Outputs** — exact shape of the artifact(s) produced.
5. **Procedure** — numbered steps the agent must follow.
6. **COBOL example** — realistic source snippet.
7. **Java 21 example** — idiomatic target snippet.
8. **Heuristics & edge cases** — REDEFINES, COMP-3 scaling, sign
   handling, OCCURS DEPENDING ON, EBCDIC vs ASCII, etc.
9. **References** — links to deeper material in `references/`.

## Testing & validation with `eval.yaml`

Each skill must have a sibling test file:

```
tests/cobol-modernization/<skill-id>/eval.yaml
```

Schema (locked in Phase 1):

```yaml
name: <human readable name>
skill: cobol-modernization/<skill-id>
fixtures:
  - path: ./fixtures/<file>
prompts:
  - input: "<prompt sent to the agent>"
    expected_contains: ["<substring>", "..."]
    expected_regex: ["<regex>", "..."]
    forbidden: ["<substring or regex>", "..."]
timeout_seconds: 60
model: claude-sonnet-4   # optional
tags: [conversion, copybook]
```

Run validation locally:

```bash
npx markdownlint-cli2 "**/*.md"
# plugin.json + marketplace.json schema checks live in eng/ (Phase 5)
```

## Writing style

- Imperative voice in procedures ("Parse the IDENTIFICATION DIVISION...").
- Prefer tables over prose for field/type mappings.
- Inline code spans for COBOL keywords and Java identifiers.
- Diagrams: Mermaid only (rendered by the host).

## Security & no-hallucination policy

- Do **not** invent vendor product names, Maven coordinates, or version
  numbers. Use a generic category phrase ("an open-source COBOL parser
  such as ProLeap or Koopa") or mark the token `<!-- VERIFY -->`.
- Skills must not embed credentials, customer data, or proprietary
  source. Use synthetic fixtures only.
- Report security issues via [`SECURITY.md`](SECURITY.md).

