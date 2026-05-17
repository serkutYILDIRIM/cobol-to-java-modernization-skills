# Example input — `extract-cobol-business-rules`

This skill consumes **two files** plus optional helpers. The realistic
example below reuses the `BILL010` program from
`analyze-cobol-program/references/example-input.cob`.

## 1. `program-profile.json` (excerpt — supplied by upstream skill)

Produced by `analyze-cobol-program` against `BILL010.cob`. Only the
fields read by this skill are shown; the full file is the artifact
described in that skill's example output.

```jsonc
{
  "schemaVersion": "1.0",
  "source": {
    "path":     "BILL010.cob",
    "dialect":  "ibm-enterprise-cobol",
    "format":   "fixed",
    "sha256":   "<sha256-of-normalised-source>"
  },
  "identification": { "programId": "BILL010" },
  "procedure": {
    "paragraphs": [
      { "name": "0000-MAIN",         "startLine":  60, "endLine":  65,
        "maxNestingDepth": 0 },
      { "name": "1000-INIT",         "startLine":  67, "endLine":  84,
        "maxNestingDepth": 1 },
      { "name": "2000-PROCESS",      "startLine":  86, "endLine":  94,
        "maxNestingDepth": 1 },
      { "name": "2100-COMPUTE-BILL", "startLine":  96, "endLine": 109,
        "maxNestingDepth": 1 },
      { "name": "2200-WRITE-BILL",   "startLine": 111, "endLine": 117,
        "maxNestingDepth": 0 },
      { "name": "9000-TERM",         "startLine": 119, "endLine": 123,
        "maxNestingDepth": 0 }
    ],
    "performEdges": [
      { "from": "0000-MAIN",    "to": "1000-INIT",         "kind": "SIMPLE" },
      { "from": "0000-MAIN",    "to": "2000-PROCESS",      "kind": "UNTIL",
        "condition": "WS-EOF" },
      { "from": "0000-MAIN",    "to": "9000-TERM",         "kind": "SIMPLE" },
      { "from": "2000-PROCESS", "to": "2100-COMPUTE-BILL", "kind": "SIMPLE" },
      { "from": "2000-PROCESS", "to": "2200-WRITE-BILL",   "kind": "SIMPLE" }
    ],
    "callEdges": [
      { "from": "2200-WRITE-BILL", "target": "BILLFMT",
        "callType": "static" }
    ],
    "execSqlBlocks": [
      { "verb": "SELECT", "tables": ["TAX_CONFIG"],
        "hostVars": [":WS-TAX-PCT", ":LK-RUN-DATE"], "line": 74 }
    ]
  },
  "metrics": { "cyclomatic": 9 }
}
```

## 2. `BILL010.cob` (verbatim — the same source the profile was built from)

Identical to
`plugins/cobol-modernization/skills/analyze-cobol-program/references/example-input.cob`.
The relevant excerpts for rule extraction are:

```cobol
       1000-INIT SECTION.
           OPEN INPUT  CUST-MASTER
                OUTPUT BILL-OUT
           PERFORM VARYING WS-MONTH-IX FROM 1 BY 1
                   UNTIL WS-MONTH-IX > 12
              MOVE WS-MONTH-IX TO WS-RATE-MONTH(WS-MONTH-IX)
              MOVE 0           TO WS-RATE-VALUE(WS-MONTH-IX)
           END-PERFORM
           EXEC SQL
              SELECT TAX_RATE
                INTO :WS-TAX-PCT
                FROM TAX_CONFIG
               WHERE EFF_DATE <= :LK-RUN-DATE
                 AND COUNTRY   = 'TR'
           END-EXEC
           IF SQLCODE NOT = 0
              ADD 1 TO WS-ERROR-CT
              MOVE 0 TO WS-TAX-PCT
           END-IF.

       2100-COMPUTE-BILL SECTION.
           EVALUATE TRUE
              WHEN CM-PLAN-CODE = 'PRE'
                 COMPUTE WS-BASE-AMT = CM-USAGE * 0.05
              WHEN CM-PLAN-CODE = 'STD'
                 COMPUTE WS-BASE-AMT = CM-USAGE * 0.08
              WHEN CM-PLAN-CODE = 'PRO'
                 COMPUTE WS-BASE-AMT = (CM-USAGE * 0.10) + 9.99
              WHEN OTHER
                 MOVE 0 TO WS-BASE-AMT
                 ADD  1 TO WS-ERROR-CT
           END-EVALUATE
           COMPUTE WS-TOTAL-AMT =
                   WS-BASE-AMT + (WS-BASE-AMT * WS-TAX-PCT / 100).
```

## 3. `domain-glossary.yaml` (optional — supplied here for richer naming)

```yaml
terms:
  CM-CUST-ID:
    javaName: customerId
    displayName: "Customer Id"
  CM-PLAN-CODE:
    javaName: customerPlanCode
    displayName: "Customer Plan Code"
  CM-USAGE:
    javaName: usageUnits
    displayName: "Usage Units"
  WS-BASE-AMT:
    javaName: baseAmount
    displayName: "Base Amount"
  WS-TAX-PCT:
    javaName: taxPercent
    displayName: "Tax Percent"
  WS-TOTAL-AMT:
    javaName: totalAmount
    displayName: "Total Amount"
  WS-EOF-FLAG:
    javaName: endOfFileReached
    displayName: "End Of File"
  LK-RUN-DATE:
    javaName: runDate
    displayName: "Run Date"
```

Run the skill with:

```
extract-cobol-business-rules \
  --program_profile_path  ./program-profile.json \
  --program_source_path   ./BILL010.cob \
  --domain_glossary_path  ./domain-glossary.yaml
```

See `example-output.md` for the artifacts produced.

