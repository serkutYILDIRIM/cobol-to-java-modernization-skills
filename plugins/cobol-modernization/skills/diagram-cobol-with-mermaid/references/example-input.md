# Example input — `diagram-cobol-with-mermaid`

This skill consumes JSON artifacts produced by upstream extractors. Below are
**realistic excerpts** of the three inputs that drive the example output in
`example-output.md`. All three excerpts describe the same program, `BILL010`,
already used by the `analyze-cobol-program` and `extract-cobol-business-rules`
fixtures.

> Bytes shown are illustrative. The real artifacts contain many more fields;
> only the subset consumed by this skill is reproduced.

---

## 1. `program-profile.json` (excerpt) — from `analyze-cobol-program`

```json
{
  "schemaVersion": "1.0",
  "source": {
    "path": "src/cobol/BILL010.cob",
    "sha256": "f3a1...e9b2"
  },
  "programId": "BILL010",
  "paragraphs": [
    { "name": "0000-MAIN",            "section": "MAIN",     "startLine":  80, "endLine": 130 },
    { "name": "1000-INIT",            "section": "MAIN",     "startLine": 135, "endLine": 180 },
    { "name": "2000-PROCESS-CUSTOMER","section": "PROCESS",  "startLine": 185, "endLine": 260 },
    { "name": "2100-VALIDATE",        "section": "PROCESS",  "startLine": 265, "endLine": 320 },
    { "name": "2200-CALC-CHARGES",    "section": "PROCESS",  "startLine": 325, "endLine": 410 },
    { "name": "2300-WRITE-INVOICE",   "section": "PROCESS",  "startLine": 415, "endLine": 470 },
    { "name": "9000-EXIT",            "section": "EXIT",     "startLine": 475, "endLine": 490 }
  ],
  "performs": [
    { "from": "0000-MAIN",             "to": "1000-INIT",             "kind": "PERFORM"        },
    { "from": "0000-MAIN",             "to": "2000-PROCESS-CUSTOMER", "kind": "PERFORM UNTIL", "label": "EOF-CUST = 'Y'" },
    { "from": "0000-MAIN",             "to": "9000-EXIT",             "kind": "PERFORM"        },
    { "from": "2000-PROCESS-CUSTOMER", "to": "2100-VALIDATE",         "kind": "PERFORM"        },
    { "from": "2000-PROCESS-CUSTOMER", "to": "2200-CALC-CHARGES",     "kind": "PERFORM"        },
    { "from": "2000-PROCESS-CUSTOMER", "to": "2300-WRITE-INVOICE",    "kind": "PERFORM"        }
  ],
  "calls": [
    { "from": "2200-CALC-CHARGES", "target": "TAXCALC",  "kind": "STATIC"  },
    { "from": "2300-WRITE-INVOICE", "target": "WS-PRINT-MOD", "kind": "DYNAMIC", "expr": "WS-PRINT-MOD" }
  ],
  "dataItems": [
    { "name": "CUSTOMER-REC", "usage": "FILE",  "copybook": "CUSTREC",  "level": "01" },
    { "name": "INVOICE-REC",  "usage": "FILE",  "copybook": "INVREC",   "level": "01" },
    { "name": "TAX-TABLE",    "usage": "TABLE", "copybook": "TAXTBL",   "level": "01" },
    { "name": "WS-STATUS",    "usage": "WORK",  "copybook": null,       "level": "01",
      "valueClause": "'N'" }
  ],
  "warnings": []
}
```

## 2. `business-rules.json` (excerpt) — from `extract-cobol-business-rules`

```json
{
  "schemaVersion": "1.0",
  "programId": "BILL010",
  "source": { "path": "src/cobol/BILL010.cob", "sha256": "f3a1...e9b2" },
  "rules": [
    { "id": "BR-BILL010-001", "groupId": "VALIDATE-CUSTOMER",
      "type": "VALIDATION", "paragraph": "2100-VALIDATE", "startLine": 270,
      "trigger": { "head": "IF CUST-STATUS = 'A'", "arm": "THEN", "priority": 1 },
      "dataItems": { "reads": ["CUST-STATUS"], "writes": ["WS-STATUS"] },
      "confidence": 0.95, "reachable": true, "programExit": false },

    { "id": "BR-BILL010-002", "groupId": "VALIDATE-CUSTOMER",
      "type": "VALIDATION", "paragraph": "2100-VALIDATE", "startLine": 280,
      "trigger": { "head": "IF CUST-STATUS = 'A'", "arm": "ELSE", "priority": 2 },
      "dataItems": { "reads": ["CUST-STATUS"], "writes": ["WS-STATUS","WS-ERR-CODE"] },
      "confidence": 0.92, "reachable": true, "programExit": false },

    { "id": "BR-BILL010-010", "groupId": "CALC-CHARGES",
      "type": "CALCULATION", "paragraph": "2200-CALC-CHARGES", "startLine": 340,
      "trigger": { "head": "EVALUATE TRUE", "arm": "WHEN CUST-TIER = 'P'", "priority": 1 },
      "dataItems": { "reads": ["CUST-TIER","BASE-AMT"], "writes": ["NET-AMT"] },
      "confidence": 0.97, "reachable": true, "programExit": false },

    { "id": "BR-BILL010-011", "groupId": "CALC-CHARGES",
      "type": "CALCULATION", "paragraph": "2200-CALC-CHARGES", "startLine": 355,
      "trigger": { "head": "EVALUATE TRUE", "arm": "WHEN CUST-TIER = 'S'", "priority": 2 },
      "dataItems": { "reads": ["CUST-TIER","BASE-AMT"], "writes": ["NET-AMT"] },
      "confidence": 0.97, "reachable": true, "programExit": false },

    { "id": "BR-BILL010-012", "groupId": "CALC-CHARGES",
      "type": "CALCULATION", "paragraph": "2200-CALC-CHARGES", "startLine": 370,
      "trigger": { "head": "EVALUATE TRUE", "arm": "WHEN OTHER", "priority": 3 },
      "dataItems": { "reads": ["BASE-AMT"], "writes": ["NET-AMT"] },
      "confidence": 0.90, "reachable": true, "programExit": false },

    { "id": "BR-BILL010-020", "groupId": "STATUS-MACHINE",
      "type": "FLAG-MUTATION", "paragraph": "2100-VALIDATE", "startLine": 275,
      "trigger": { "head": "MOVE 'V'", "arm": "TO WS-STATUS", "priority": 1 },
      "dataItems": { "reads": [], "writes": ["WS-STATUS"] },
      "confidence": 0.99, "reachable": true, "programExit": false },

    { "id": "BR-BILL010-021", "groupId": "STATUS-MACHINE",
      "type": "FLAG-MUTATION", "paragraph": "2300-WRITE-INVOICE", "startLine": 430,
      "trigger": { "head": "MOVE 'I'", "arm": "TO WS-STATUS", "priority": 1 },
      "dataItems": { "reads": [], "writes": ["WS-STATUS"] },
      "confidence": 0.99, "reachable": true, "programExit": false },

    { "id": "BR-BILL010-022", "groupId": "STATUS-MACHINE",
      "type": "FLAG-MUTATION", "paragraph": "9000-EXIT", "startLine": 480,
      "trigger": { "head": "MOVE 'D'", "arm": "TO WS-STATUS", "priority": 1 },
      "dataItems": { "reads": [], "writes": ["WS-STATUS"] },
      "confidence": 0.99, "reachable": true, "programExit": true }
  ],
  "warnings": [],
  "chaining": { "styleProfileSeen": false, "profileSchemaVersion": "1.0" }
}
```

## 3. `job-flow.json` (excerpt) — from `map-mainframe-job-flow`

```json
{
  "schemaVersion": "1.0",
  "jobs": [
    { "jobName": "BILL010J", "class": "A", "msgClass": "X", "restart": null,
      "steps": [
        { "stepName": "STEP010", "source": "BILL010J.jcl", "program": "IDCAMS",
          "cond": null, "ifGuard": null },
        { "stepName": "STEP020", "source": "BILL010J.jcl", "program": "BILL010",
          "cond": "(0,NE,STEP010)", "ifGuard": null },
        { "stepName": "STEP030.COPYSTEP", "source": "ARCHPROC.prc",
          "program": "IEBGENER", "cond": null, "ifGuard": "RC=0" }
      ]
    }
  ],
  "datasetEdges": [
    { "from": "STEP010", "to": "STEP020", "dsn": "PAY.CUST.VSAM",        "mode": "DEFINE→READ" },
    { "from": "STEP020", "to": "STEP030.COPYSTEP", "dsn": "PAY.INV.GDG(+1)", "mode": "WRITE→READ" }
  ],
  "programs": ["BILL010","IDCAMS","IEBGENER","TAXCALC"],
  "warnings": [],
  "chaining": { "styleProfileSeen": false, "profileSchemaVersion": "1.0" }
}
```

## 4. `options.yaml` (caller-supplied)

```yaml
diagrams:
  - paragraph-flow
  - call-graph
  - rule-tree
  - job-dag
  - data-er
  - state-machine
maxNodesPerDiagram: 60
maxEdgesPerDiagram: 120
includeRuleBadges: true
includeLineNumbers: true
direction:
  paragraph-flow: TD
  call-graph: LR
  job-dag: LR
```

