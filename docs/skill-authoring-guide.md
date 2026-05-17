# Skill Authoring Guide

> Stub. Full content will be filled in Phase 5.

## Table of contents

1. Audience and prerequisites
2. The agentskills.io SKILL.md standard at a glance
3. Frontmatter rules
   1. Only `name` and `description`
   2. Embedding "when to use" / "when NOT to use" in `description`
4. Body structure (recommended sections)
   1. Purpose
   2. Inputs / Outputs
   3. Procedure (numbered, imperative)
   4. COBOL example (realistic constructs only)
   5. Java 21 example (records, sealed types, pattern matching, virtual
      threads)
   6. Heuristics & edge cases
   7. References
5. Progressive disclosure
   1. When to extract into `scripts/`
   2. When to extract into `references/`
   3. When to extract into `assets/`
6. Naming conventions
   1. Kebab-case, action-verb-led
   2. Skill family prefixes (`analyze-`, `extract-`, `map-`, `convert-`,
      `transpile-`, `plan-`, `generate-`, `scan-`, `diagram-`)
7. Writing `eval.yaml`
   1. Fixtures
   2. `expected_contains` vs `expected_regex` vs `forbidden`
   3. Tagging strategy
8. No-hallucination policy in practice
   1. Generic category phrases
   2. The `<!-- VERIFY -->` marker
   3. Reference-domain allowlist (`eng/known-domains.txt`)
9. Reviewing a skill PR
10. Publishing a new plugin version

