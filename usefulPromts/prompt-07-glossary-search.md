PHASE OPT — TARGETED PATTERN/KEYWORD SEARCH

Use this prompt whenever you want the agent to find specific COBOL
constructs WITHOUT loading the whole file.

Trigger: "Find <PATTERN> in <PROGRAM_NAME>"
Example: "Find all COMPUTE statements involving TAX in PAYROLL01"
Example: "Find every paragraph that touches the EMPLOYEE-MASTER file"
Example: "List all EVALUATE blocks with more than 5 WHEN branches"

PRE-FLIGHT:
- Read STATE/conversions/<PROGRAM_NAME>/01a-manifest.md ONLY.
- Identify candidate line ranges from the manifest tables. Open ONLY
  those ranges. Do NOT read the whole COBOL file.
- Use grep/regex tools where possible (much cheaper than semantic
  read).

OUTPUT (in chat, no file written by default):

  | # | Paragraph | Lines | Snippet (≤ 5 lines) | Notes |

If the user explicitly says "save findings", write to
STATE/conversions/<PROGRAM_NAME>/findings-<TIMESTAMP>.md.

═══════════════════════════════════════════════════════════════════════
RULES
═══════════════════════════════════════════════════════════════════════

- Maximum 30 hits per response. If more, summarize and ask the user
  to narrow.
- Never load > 1000 lines total across all opened ranges.
- Never modify src/.
- Never commit.

This is a READ-ONLY exploratory tool. Findings can feed the next
Pass B implementation session.