PHASE 0 — REPOSITORY PROFILING (CHECKPOINTED, 3 FILES AT A TIME)

Goal: Produce `.copilot-conversion/STATE/repo-profile.md` plus checkpoint
files, so a future conversion follows the repo's house style without
re-asking and without overloading any single session.

═══════════════════════════════════════════════════════════════════════
STEP A — INITIAL RECONNAISSANCE (cheap, deterministic)
═══════════════════════════════════════════════════════════════════════

Use keyword / regex / file listing tools ONLY. Do NOT read source files
deeply yet. Produce a SHORT report in chat covering:

1. Build tool + version (from pom.xml / build.gradle / settings.gradle)
2. Java version (from toolchain, sourceCompatibility, or release flag)
3. Spring Boot version (from parent POM / plugins)
4. Root package (from src/main/java/.../ deepest single chain)
5. Folder layout (top-level src/main/java sub-packages)
6. Approximate count of .java files

Ask the user up to 5 numbered questions if anything is ambiguous
(e.g., monorepo with multiple modules — which to scan?).

Wait for answers.

═══════════════════════════════════════════════════════════════════════
STEP B — BUILD THE SCAN PLAN
═══════════════════════════════════════════════════════════════════════

Produce `STATE/repo-scan-plan.md` listing:

- All Java source files grouped by ARTIFACT TYPE detected by file
  suffix / annotation keyword grep:
  Controller, Service, Repository, Entity, DTO/Record,
  Mapper, Configuration, ExceptionHandler, Test
- For each type, list up to 5 CANDIDATE files to inspect deeply
  (prefer files with many references — use simple usage-count
  heuristics, not semantic analysis).
- Group the candidates into checkpoints of EXACTLY 3 files each.
- Number the checkpoints CP-01, CP-02, ...

End STEP B in chat with:
"Scan plan ready. <N> checkpoints proposed.
Reply `continue` to start CP-01 (3 files)."

STOP. Wait for user.

═══════════════════════════════════════════════════════════════════════
STEP C — EXECUTE ONE CHECKPOINT AT A TIME
═══════════════════════════════════════════════════════════════════════

Trigger: user says `continue` or `run CP-NN`.

For the next checkpoint:
- Open ONLY the 3 files in that checkpoint.
- Extract per-file:
  package, class type, annotations used, naming style,
  exception strategy, logging usage, persistence usage,
  validation usage, test style (if test file)
- Append findings to `STATE/repo-scan-checkpoint-<NN>.md`
  (one file per checkpoint).

End the checkpoint in chat with:
"CP-<NN> done. Files analyzed: <list>.
Remaining checkpoints: <count>.
Reply `continue` for CP-<NN+1> or `synthesize` to build repo-profile.md now."

STOP. Wait for user.

═══════════════════════════════════════════════════════════════════════
STEP D — SYNTHESIZE THE PROFILE (final checkpoint)
═══════════════════════════════════════════════════════════════════════

Trigger: user says `synthesize`.

Read ALL `STATE/repo-scan-checkpoint-*.md` files. Produce ONE
consolidated `STATE/repo-profile.md` covering:

1. Build & runtime
2. Package layout & module structure
3. Naming conventions (per layer)
4. Persistence stack
5. API style
6. Exception handling
7. Logging & observability
8. Testing stack
9. Configuration
10. Code style (Lombok / MapStruct / Checkstyle / Spotless)
11. Domain glossary (10–20 terms with canonical Java types)
12. CANONICAL EXAMPLES TABLE — for each artifact type, list ONE
    exemplary file path (this is what future phases will open).

End chat with a one-line summary and: "Profile complete. STATE/
checkpoint files can be deleted now (they are not committed)."

═══════════════════════════════════════════════════════════════════════
RULES
═══════════════════════════════════════════════════════════════════════

- Maximum 3 source files per checkpoint.
- Never load > 1500 total lines in one session.
- Never use semantic search across the whole repo.
- Do not commit, push, or run git.
- Do not modify src/.