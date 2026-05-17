# Example output — `extract-cobol-business-rules`

Running this skill against the inputs from `example-input.md`
produces the two artifacts shown below.

## 1. `business-rules.json` (excerpt — deterministic, sorted by startLine then id)

```jsonc
{
  "schemaVersion": "1.0",
  "source": {
    "profilePath":  "./program-profile.json",
    "programPath":  "./BILL010.cob",
    "programId":    "BILL010",
    "sourceSha256": "<sha256-of-normalised-source>"
  },
  "summary": {
    "ruleCount": 11,
    "byType": {
      "CALCULATION":    5,
      "VALIDATION":     0,
      "BRANCHING":      2,
      "LOOKUP":         1,
      "MAPPING":        1,
      "FLAG-MUTATION":  0,
      "IO-EFFECT":      1,
      "ERROR-HANDLING": 1
    },
    "unreachableRules": 0
  },
  "rules": [
    {
      "id": "BR-1000-INIT-001",
      "paragraph": "1000-INIT", "section": "1000-INIT",
      "startLine": 69, "endLine": 73,
      "type": "BRANCHING",
      "statement": "Initialises the monthly Rate Table to zero for
                    months 1 through 12 before any customer is read.",
      "trigger": { "head": "PERFORM VARYING",
                   "arm":  "WS-MONTH-IX FROM 1 BY 1 UNTIL WS-MONTH-IX > 12",
                   "priority": 1 },
      "expression": null,
      "dataItems": {
        "reads":  [],
        "writes": [
          { "name": "WS-RATE-MONTH", "pic": "9(2)",        "level": 10,
            "source": "WORKING-STORAGE" },
          { "name": "WS-RATE-VALUE", "pic": "S9(3)V99 COMP-3", "level": 10,
            "source": "WORKING-STORAGE" }
        ]
      },
      "domainTerms": [],
      "sourceSnippet": "PERFORM VARYING WS-MONTH-IX FROM 1 BY 1\n        UNTIL WS-MONTH-IX > 12\n   MOVE WS-MONTH-IX TO WS-RATE-MONTH(WS-MONTH-IX)\n   MOVE 0           TO WS-RATE-VALUE(WS-MONTH-IX)\nEND-PERFORM",
      "confidence": 0.90,
      "reachable": true
    },
    {
      "id": "BR-1000-INIT-002",
      "groupId": "G-1000-INIT-001",
      "paragraph": "1000-INIT", "section": "1000-INIT",
      "startLine": 74, "endLine": 80,
      "type": "LOOKUP",
      "statement": "Looks up the country Tax Percent effective on the
                    Run Date for country 'TR' from the TAX_CONFIG table.",
      "trigger": { "head": "EXEC SQL", "arm": "ALWAYS", "priority": 1 },
      "expression": "SELECT TAX_RATE FROM TAX_CONFIG WHERE EFF_DATE <= :LK-RUN-DATE AND COUNTRY = 'TR'",
      "dataItems": {
        "reads":  [
          { "name": "LK-RUN-DATE", "pic": "9(8)", "level": 1,
            "source": "LINKAGE" }
        ],
        "writes": [
          { "name": "WS-TAX-PCT",  "pic": "S9(3)V99 COMP-3", "level": 5,
            "source": "WORKING-STORAGE" }
        ]
      },
      "domainTerms": ["Run Date", "Tax Percent"],
      "sourceSnippet": "EXEC SQL\n   SELECT TAX_RATE\n     INTO :WS-TAX-PCT\n     FROM TAX_CONFIG\n    WHERE EFF_DATE <= :LK-RUN-DATE\n      AND COUNTRY   = 'TR'\nEND-EXEC",
      "confidence": 1.00,
      "reachable": true
    },
    {
      "id": "BR-1000-INIT-003",
      "groupId": "G-1000-INIT-001",
      "paragraph": "1000-INIT", "section": "1000-INIT",
      "startLine": 81, "endLine": 84,
      "type": "ERROR-HANDLING",
      "statement": "If the Tax Percent lookup fails (SQLCODE != 0),
                    increments the error counter and defaults the Tax
                    Percent to zero (no tax applied).",
      "trigger": { "head": "IF", "arm": "SQLCODE != 0", "priority": 1 },
      "expression": "WS-ERROR-CT = WS-ERROR-CT + 1; WS-TAX-PCT = 0",
      "dataItems": {
        "reads":  [
          { "name": "SQLCODE", "pic": "S9(9) COMP",
            "level": 1, "source": "WORKING-STORAGE" }
        ],
        "writes": [
          { "name": "WS-ERROR-CT", "pic": "S9(7) COMP-3", "level": 5,
            "source": "WORKING-STORAGE" },
          { "name": "WS-TAX-PCT",  "pic": "S9(3)V99 COMP-3", "level": 5,
            "source": "WORKING-STORAGE" }
        ]
      },
      "domainTerms": ["Tax Percent"],
      "sourceSnippet": "IF SQLCODE NOT = 0\n   ADD 1 TO WS-ERROR-CT\n   MOVE 0 TO WS-TAX-PCT\nEND-IF",
      "confidence": 0.90,
      "reachable": true
    },
    {
      "id": "BR-2000-PROCESS-001",
      "paragraph": "2000-PROCESS", "section": "2000-PROCESS",
      "startLine": 87, "endLine": 89,
      "type": "IO-EFFECT",
      "statement": "Reads the next Customer Master record; marks
                    End Of File when no more records are available.",
      "trigger": { "head": "READ", "arm": "AT END", "priority": 1 },
      "expression": null,
      "dataItems": {
        "reads":  [ { "name": "CUST-MASTER", "source": "FILE" } ],
        "writes": [
          { "name": "WS-EOF-FLAG", "pic": "X", "level": 1,
            "source": "WORKING-STORAGE" }
        ]
      },
      "domainTerms": ["End Of File"],
      "sourceSnippet": "READ CUST-MASTER NEXT\n   AT END SET WS-EOF TO TRUE\nEND-READ",
      "confidence": 1.00,
      "reachable": true
    },
    {
      "id": "BR-2100-COMPUTE-BILL-001",
      "groupId": "G-2100-COMPUTE-BILL-001",
      "paragraph": "2100-COMPUTE-BILL", "section": "2100-COMPUTE-BILL",
      "startLine": 98, "endLine":  99,
      "type": "CALCULATION",
      "statement": "When the Customer Plan Code is 'PRE', the Base
                    Amount equals Usage Units × 0.05.",
      "trigger": { "head": "EVALUATE TRUE",
                   "arm":  "CM-PLAN-CODE == 'PRE'", "priority": 1 },
      "expression": "WS-BASE-AMT = CM-USAGE * 0.05",
      "dataItems": {
        "reads":  [ { "name": "CM-PLAN-CODE", "source": "COPY:CUSTREC" },
                    { "name": "CM-USAGE",     "source": "COPY:CUSTREC" } ],
        "writes": [ { "name": "WS-BASE-AMT",
                      "pic": "S9(7)V99 COMP-3", "level": 5,
                      "source": "WORKING-STORAGE" } ]
      },
      "domainTerms": ["Customer Plan Code", "Usage Units", "Base Amount"],
      "sourceSnippet": "WHEN CM-PLAN-CODE = 'PRE'\n   COMPUTE WS-BASE-AMT = CM-USAGE * 0.05",
      "confidence": 0.80,
      "reachable": true
    },
    {
      "id": "BR-2100-COMPUTE-BILL-002",
      "groupId": "G-2100-COMPUTE-BILL-001",
      "paragraph": "2100-COMPUTE-BILL", "section": "2100-COMPUTE-BILL",
      "startLine": 100, "endLine": 101,
      "type": "CALCULATION",
      "statement": "When the Customer Plan Code is 'STD', the Base
                    Amount equals Usage Units × 0.08.",
      "trigger": { "head": "EVALUATE TRUE",
                   "arm":  "CM-PLAN-CODE == 'STD'", "priority": 2 },
      "expression": "WS-BASE-AMT = CM-USAGE * 0.08",
      "dataItems": { "reads": [ { "name": "CM-PLAN-CODE", "source": "COPY:CUSTREC" },
                                { "name": "CM-USAGE",     "source": "COPY:CUSTREC" } ],
                     "writes": [ { "name": "WS-BASE-AMT",
                                   "source": "WORKING-STORAGE" } ] },
      "domainTerms": ["Customer Plan Code", "Usage Units", "Base Amount"],
      "sourceSnippet": "WHEN CM-PLAN-CODE = 'STD'\n   COMPUTE WS-BASE-AMT = CM-USAGE * 0.08",
      "confidence": 0.80,
      "reachable": true
    },
    {
      "id": "BR-2100-COMPUTE-BILL-003",
      "groupId": "G-2100-COMPUTE-BILL-001",
      "paragraph": "2100-COMPUTE-BILL", "section": "2100-COMPUTE-BILL",
      "startLine": 102, "endLine": 103,
      "type": "CALCULATION",
      "statement": "When the Customer Plan Code is 'PRO', the Base
                    Amount equals Usage Units × 0.10 + 9.99.",
      "trigger": { "head": "EVALUATE TRUE",
                   "arm":  "CM-PLAN-CODE == 'PRO'", "priority": 3 },
      "expression": "WS-BASE-AMT = (CM-USAGE * 0.10) + 9.99",
      "dataItems": { "reads": [ { "name": "CM-PLAN-CODE", "source": "COPY:CUSTREC" },
                                { "name": "CM-USAGE",     "source": "COPY:CUSTREC" } ],
                     "writes": [ { "name": "WS-BASE-AMT",
                                   "source": "WORKING-STORAGE" } ] },
      "domainTerms": ["Customer Plan Code", "Usage Units", "Base Amount"],
      "sourceSnippet": "WHEN CM-PLAN-CODE = 'PRO'\n   COMPUTE WS-BASE-AMT = (CM-USAGE * 0.10) + 9.99",
      "confidence": 0.80,
      "reachable": true
    },
    {
      "id": "BR-2100-COMPUTE-BILL-004",
      "groupId": "G-2100-COMPUTE-BILL-001",
      "paragraph": "2100-COMPUTE-BILL", "section": "2100-COMPUTE-BILL",
      "startLine": 104, "endLine": 106,
      "type": "CALCULATION",
      "statement": "Default fallback: when the Customer Plan Code is
                    none of 'PRE','STD','PRO', the Base Amount is set
                    to zero and the error counter is incremented.",
      "trigger": { "head": "EVALUATE TRUE", "arm": "DEFAULT",
                   "priority": 999 },
      "expression": "WS-BASE-AMT = 0; WS-ERROR-CT = WS-ERROR-CT + 1",
      "dataItems": { "reads": [ { "name": "CM-PLAN-CODE", "source": "COPY:CUSTREC" } ],
                     "writes": [ { "name": "WS-BASE-AMT",  "source": "WORKING-STORAGE" },
                                 { "name": "WS-ERROR-CT",  "source": "WORKING-STORAGE" } ] },
      "domainTerms": ["Customer Plan Code", "Base Amount"],
      "sourceSnippet": "WHEN OTHER\n   MOVE 0 TO WS-BASE-AMT\n   ADD  1 TO WS-ERROR-CT",
      "confidence": 0.80,
      "reachable": true
    },
    {
      "id": "BR-2100-COMPUTE-BILL-005",
      "paragraph": "2100-COMPUTE-BILL", "section": "2100-COMPUTE-BILL",
      "startLine": 108, "endLine": 109,
      "type": "CALCULATION",
      "statement": "The Total Amount equals the Base Amount plus
                    (Base Amount × Tax Percent / 100).",
      "trigger": { "head": "ALWAYS", "arm": "ALWAYS", "priority": 1 },
      "expression": "WS-TOTAL-AMT = WS-BASE-AMT + (WS-BASE-AMT * WS-TAX-PCT / 100)",
      "dataItems": { "reads":  [ { "name": "WS-BASE-AMT", "source": "WORKING-STORAGE" },
                                 { "name": "WS-TAX-PCT",  "source": "WORKING-STORAGE" } ],
                     "writes": [ { "name": "WS-TOTAL-AMT","source": "WORKING-STORAGE" } ] },
      "domainTerms": ["Base Amount", "Tax Percent", "Total Amount"],
      "sourceSnippet": "COMPUTE WS-TOTAL-AMT =\n        WS-BASE-AMT + (WS-BASE-AMT * WS-TAX-PCT / 100)",
      "confidence": 1.00,
      "reachable": true
    },
    {
      "id": "BR-2200-WRITE-BILL-001",
      "paragraph": "2200-WRITE-BILL", "section": "2200-WRITE-BILL",
      "startLine": 112, "endLine": 116,
      "type": "IO-EFFECT",
      "statement": "Formats the bill via the BILLFMT sub-program and
                    writes one record to the BILL-OUT sequential file,
                    incrementing the billed counter.",
      "trigger": { "head": "CALL", "arm": "ALWAYS", "priority": 1 },
      "expression": null,
      "dataItems": {
        "reads":  [ { "name": "CM-CUST-ID",   "source": "COPY:CUSTREC" },
                    { "name": "WS-TOTAL-AMT", "source": "WORKING-STORAGE" } ],
        "writes": [ { "name": "BILL-OUT-REC", "pic": "X(200)",
                      "level": 1, "source": "FILE" },
                    { "name": "WS-BILLED-CT", "source": "WORKING-STORAGE" } ]
      },
      "domainTerms": ["Customer Id", "Total Amount"],
      "sourceSnippet": "CALL 'BILLFMT' USING CM-CUST-ID\n                     WS-TOTAL-AMT\n                     BILL-OUT-REC\nWRITE BILL-OUT-REC\nADD 1 TO WS-BILLED-CT",
      "confidence": 1.00,
      "reachable": true
    },
    {
      "id": "BR-9000-TERM-001",
      "paragraph": "9000-TERM", "section": "9000-TERM",
      "startLine": 119, "endLine": 122,
      "type": "IO-EFFECT",
      "statement": "Closes both files and writes the run summary
                    (read / billed / error counts) to the operator log.",
      "trigger": { "head": "ALWAYS", "arm": "ALWAYS", "priority": 1 },
      "expression": null,
      "dataItems": { "reads":  [ { "name": "WS-READ-CT",   "source": "WORKING-STORAGE" },
                                 { "name": "WS-BILLED-CT", "source": "WORKING-STORAGE" },
                                 { "name": "WS-ERROR-CT",  "source": "WORKING-STORAGE" } ],
                     "writes": [ { "name": "CUST-MASTER", "source": "FILE" },
                                 { "name": "BILL-OUT",    "source": "FILE" } ] },
      "domainTerms": [],
      "sourceSnippet": "CLOSE CUST-MASTER BILL-OUT\nDISPLAY 'READ='   WS-READ-CT\n        ' BILLED=' WS-BILLED-CT\n        ' ERR='   WS-ERROR-CT",
      "confidence": 0.90,
      "reachable": true
    }
  ],
  "programExit": { "kind": "GOBACK", "paragraph": "0000-MAIN", "line": 64 },
  "warnings":   [ "W-FIELD-UNRESOLVED:CM-CUST-ID",
                  "W-FIELD-UNRESOLVED:CM-PLAN-CODE",
                  "W-FIELD-UNRESOLVED:CM-USAGE" ],
  "chaining":   { "styleProfileSeen": false,
                  "profileSchemaVersion": "1.0" }
}
```

> The three `W-FIELD-UNRESOLVED` warnings are expected because
> `copybook_dirs` was not supplied — the `CUSTREC` copybook is
> unresolved in the upstream profile, so PIC/level info for `CM-*`
> fields cannot be enriched. They do not lower the rules below
> `confidence 0.50` thanks to the glossary entries.

## 2. `business-rules.md` (review document)

```markdown
# BILL010 — business rules
Profile: ./program-profile.json   Source: ./BILL010.cob   Rules: 11

## 1000-INIT  (3 rules)

- **BR-1000-INIT-001**  BRANCHING   (conf 0.90)
  Initialises the monthly Rate Table to zero for months 1..12.
      PERFORM VARYING WS-MONTH-IX FROM 1 BY 1 UNTIL WS-MONTH-IX > 12

- **BR-1000-INIT-002**  LOOKUP      (conf 1.00, group G-1000-INIT-001)
  Looks up the country Tax Percent effective on the Run Date for
  country 'TR' from TAX_CONFIG.
      SELECT TAX_RATE INTO :WS-TAX-PCT FROM TAX_CONFIG
       WHERE EFF_DATE <= :LK-RUN-DATE AND COUNTRY = 'TR'

- **BR-1000-INIT-003**  ERROR-HANDLING (conf 0.90, group G-1000-INIT-001)
  If the Tax Percent lookup fails (SQLCODE != 0), increment the error
  counter and default Tax Percent to zero.
      IF SQLCODE NOT = 0 ...

## 2000-PROCESS  (1 rule)

- **BR-2000-PROCESS-001**  IO-EFFECT   (conf 1.00)
  Reads the next Customer Master record; marks End Of File at end.

## 2100-COMPUTE-BILL  (5 rules — group G-2100-COMPUTE-BILL-001 = EVALUATE TRUE)

- **BR-2100-COMPUTE-BILL-001**  CALCULATION  (conf 0.80, prio 1)
  Plan 'PRE' : Base Amount = Usage Units × 0.05
- **BR-2100-COMPUTE-BILL-002**  CALCULATION  (conf 0.80, prio 2)
  Plan 'STD' : Base Amount = Usage Units × 0.08
- **BR-2100-COMPUTE-BILL-003**  CALCULATION  (conf 0.80, prio 3)
  Plan 'PRO' : Base Amount = Usage Units × 0.10 + 9.99
- **BR-2100-COMPUTE-BILL-004**  CALCULATION  (conf 0.80, prio 999 = DEFAULT)
  Unknown plan : Base Amount = 0 and error counter increments.
- **BR-2100-COMPUTE-BILL-005**  CALCULATION  (conf 1.00)
  Total Amount = Base Amount + (Base Amount × Tax Percent / 100)

## 2200-WRITE-BILL  (1 rule)

- **BR-2200-WRITE-BILL-001**  IO-EFFECT   (conf 1.00)
  Formats the bill via BILLFMT and writes BILL-OUT; increments billed
  counter.

## 9000-TERM  (1 rule)

- **BR-9000-TERM-001**  IO-EFFECT   (conf 0.90)
  Closes files and writes run summary (read / billed / error counts).

## Warnings
- W-FIELD-UNRESOLVED:CM-CUST-ID
- W-FIELD-UNRESOLVED:CM-PLAN-CODE
- W-FIELD-UNRESOLVED:CM-USAGE
```

## Chaining hint

Feed `business-rules.json` into:

- `transpile-cobol-to-java21` — generates one Java method per rule
  with `@RuleId("BR-2100-COMPUTE-BILL-003")` annotations.
- `generate-modernization-tests` — generates 11 characterisation
  tests, one per rule id.
- `plan-strangler-fig-migration` — uses
  `summary.byType.CALCULATION` and groupings to pick the billing
  slice as the first migration candidate.

