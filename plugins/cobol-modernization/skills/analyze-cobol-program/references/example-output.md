# Example output — `analyze-cobol-program`

Running this skill against `references/example-input.cob` (program
`BILL010`) produces the two artifacts shown below in the agent's
working directory.

## 1. `program-profile.json` (excerpt — full file is deterministic)

```jsonc
{
  "schemaVersion": "1.0",
  "source": {
    "path": "references/example-input.cob",
    "dialect": "ibm-enterprise-cobol",
    "format": "fixed",
    "sha256": "<sha256-of-normalised-source>"
  },
  "identification": {
    "programId": "BILL010",
    "author": "MODERNIZATION-TEAM",
    "dateWritten": "1998-03-12"
  },
  "environment": {
    "files": [
      { "logicalName": "CUST-MASTER", "ddName": "CUSTMSTR",
        "organization": "INDEXED",    "accessMode": "DYNAMIC",
        "recordKey": "CM-CUST-ID",    "statusVar": "WS-CM-STATUS" },
      { "logicalName": "BILL-OUT",    "ddName": "BILLOUT",
        "organization": "SEQUENTIAL", "accessMode": "SEQUENTIAL",
        "recordKey": null,            "statusVar": "WS-BO-STATUS" }
    ]
  },
  "data": {
    "fileSection": [
      { "fd": "CUST-MASTER", "record01": "CUST-MASTER-REC" },
      { "fd": "BILL-OUT",    "record01": "BILL-OUT-REC" }
    ],
    "workingStorage": [
      { "name": "WS-CM-STATUS",  "flags": [] },
      { "name": "WS-BO-STATUS",  "flags": [] },
      { "name": "WS-EOF-FLAG",   "flags": [] },
      { "name": "WS-COUNTERS",   "flags": ["COMP-3"] },
      { "name": "WS-AMOUNTS",    "flags": ["COMP-3"] },
      { "name": "WS-RATE-TBL",   "flags": ["OCCURS","COMP-3"] },
      { "name": "WS-RATE-RAW",   "flags": ["REDEFINES"] },
      { "name": "WS-MONTH-IX",   "flags": [] }
    ],
    "linkage": [
      { "name": "LK-RUN-DATE" },
      { "name": "LK-RETURN-CODE" }
    ],
    "copybooks": [
      { "member": "CUSTREC",
        "resolvedPath": null,
        "replacing": [ ["==:PFX:==", "==CM=="] ],
        "includedAtLine": 26 }
    ]
  },
  "procedure": {
    "paragraphs": [
      { "name": "0000-MAIN",         "section": "0000-MAIN",
        "startLine": 60, "endLine": 65, "loc": 6,
        "fanIn": 0, "fanOut": 3, "maxNestingDepth": 0 },
      { "name": "1000-INIT",         "section": "1000-INIT",
        "startLine": 67, "endLine": 84, "loc": 18,
        "fanIn": 1, "fanOut": 0, "maxNestingDepth": 1 },
      { "name": "2000-PROCESS",      "section": "2000-PROCESS",
        "startLine": 86, "endLine": 94, "loc": 9,
        "fanIn": 1, "fanOut": 2, "maxNestingDepth": 1 },
      { "name": "2100-COMPUTE-BILL", "section": "2100-COMPUTE-BILL",
        "startLine": 96, "endLine": 109, "loc": 14,
        "fanIn": 1, "fanOut": 0, "maxNestingDepth": 1 },
      { "name": "2200-WRITE-BILL",   "section": "2200-WRITE-BILL",
        "startLine": 111, "endLine": 117, "loc": 7,
        "fanIn": 1, "fanOut": 0, "maxNestingDepth": 0 },
      { "name": "9000-TERM",         "section": "9000-TERM",
        "startLine": 119, "endLine": 123, "loc": 5,
        "fanIn": 1, "fanOut": 0, "maxNestingDepth": 0 }
    ],
    "performEdges": [
      { "from": "0000-MAIN", "to": "1000-INIT",
        "kind": "SIMPLE",   "condition": null, "line": 61 },
      { "from": "0000-MAIN", "to": "2000-PROCESS",
        "kind": "UNTIL",    "condition": "WS-EOF", "line": 62 },
      { "from": "0000-MAIN", "to": "9000-TERM",
        "kind": "SIMPLE",   "condition": null, "line": 63 },
      { "from": "1000-INIT", "to": "<inline>",
        "kind": "VARYING",
        "condition": "WS-MONTH-IX FROM 1 BY 1 UNTIL WS-MONTH-IX > 12",
        "line": 70 },
      { "from": "2000-PROCESS", "to": "2100-COMPUTE-BILL",
        "kind": "SIMPLE", "condition": null, "line": 92 },
      { "from": "2000-PROCESS", "to": "2200-WRITE-BILL",
        "kind": "SIMPLE", "condition": null, "line": 93 }
    ],
    "callEdges": [
      { "from": "2200-WRITE-BILL", "target": "BILLFMT",
        "callType": "static", "line": 112,
        "using": ["CM-CUST-ID","WS-TOTAL-AMT","BILL-OUT-REC"] }
    ],
    "gotoEdges": [],
    "execSqlBlocks": [
      { "verb": "SELECT",
        "tables": ["TAX_CONFIG"],
        "hostVars": [":WS-TAX-PCT", ":LK-RUN-DATE"],
        "line": 74 }
    ],
    "execCicsBlocks": []
  },
  "metrics": {
    "loc": { "total": 123, "code": 109, "comment": 4 },
    "cyclomatic": 9,
    "deadParagraphs": []
  },
  "warnings": [
    { "code": "W-COPY-UNRESOLVED", "detail": "CUSTREC" }
  ],
  "chaining": { "styleProfileSeen": false }
}
```

## 2. `program-brief.md`

```markdown
# BILL010 — program brief
Profile: ./program-profile.json

Purpose (from header comments):
  Monthly billing engine for retail postpaid customers.
  Reads CUST-MASTER (VSAM KSDS), applies plan-specific tariffs,
  looks up tax rate from DB2, writes BILL-OUT.

Structure
- Paragraphs: 6   PERFORM edges: 6   CALLs: 1 (static: BILLFMT)
- EXEC SQL: 1 (SELECT on TAX_CONFIG)   EXEC CICS: 0   GO TO: 0
- Files: CUST-MASTER (VSAM INDEXED), BILL-OUT (SEQUENTIAL)
- Copybooks: CUSTREC  (UNRESOLVED — supply copybook_dirs)
- LINKAGE: LK-RUN-DATE, LK-RETURN-CODE

Complexity
- LOC total/code/comment: 123 / 109 / 4
- Cyclomatic: 9
- Dead paragraphs: none

Top fan-in paragraphs
  1. 1000-INIT          (1)
  2. 2000-PROCESS       (1)
  3. 2100-COMPUTE-BILL  (1)
  4. 2200-WRITE-BILL    (1)
  5. 9000-TERM          (1)

Warnings
- W-COPY-UNRESOLVED: CUSTREC
```

## Chaining hint

Feed `program-profile.json` into:

- `extract-cobol-business-rules` → derives rules from
  `2100-COMPUTE-BILL` (plan-tariff EVALUATE) and `1000-INIT` (tax
  lookup fallback on SQLCODE ≠ 0).
- `diagram-cobol-with-mermaid` → renders the PERFORM graph plus
  the CALL to `BILLFMT` and the EXEC SQL node.
- `map-vsam-db2-to-jpa` → maps `CUST-MASTER` (INDEXED, key
  `CM-CUST-ID`) to a JPA entity and `TAX_CONFIG` to a read-only
  repository.

