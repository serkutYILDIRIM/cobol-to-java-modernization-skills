# Example output — `map-mainframe-job-flow`

Inputs:

- `jcl_paths = ["references/example-input.jcl"]`
- `proc_dirs = ["./procs"]` (assume `ARCHPROC` resolves)
- `symbol_overrides = {}`

Two artifacts are written to the agent's current working directory:
`job-flow.json` and `job-flow.md`.

## `job-flow.json` (excerpt)

```json
{
  "schemaVersion": "1.0",
  "sources": [
    {
      "path": "references/example-input.jcl",
      "encoding": "ascii",
      "sha256": "REPLACE_WITH_SHA256_OF_NORMALISED_JCL"
    }
  ],
  "symbolOverrides": {},
  "jobs": [
    {
      "jobName": "BILL010J",
      "class": "A",
      "msgClass": "X",
      "restart": "STEP020",
      "jcllib": ["PROD.PROCLIB", "SHARED.PROCLIB"],
      "joblib": ["PROD.LOADLIB", "PROD.DB2.LOADLIB"],
      "steps": [
        {
          "stepName": "STEP010",
          "source": "inline",
          "program": "IDCAMS",
          "programDynamic": false,
          "steplib": [],
          "cond": null,
          "ifGuard": null,
          "chkpt": null,
          "ddStatements": [
            { "ddName": "SYSPRINT", "dsn": null,
              "disp": ["NEW","DELETE","DELETE"],
              "gdg": false, "gdgBias": null,
              "sysout": "*", "instream": false,
              "instreamLines": [0,0], "concat": false,
              "dcb": {}, "sms": {} },
            { "ddName": "SYSIN", "dsn": null,
              "disp": ["NEW","DELETE","DELETE"],
              "gdg": false, "gdgBias": null,
              "sysout": null, "instream": true,
              "instreamLines": [18, 24], "concat": false,
              "dcb": {}, "sms": {} }
          ]
        },
        {
          "stepName": "STEP020",
          "source": "inline",
          "program": "BILL010",
          "programDynamic": false,
          "steplib": ["PROD.BILL010.LOADLIB"],
          "cond": null,
          "ifGuard": null,
          "chkpt": null,
          "ddStatements": [
            { "ddName": "CUSTMAST",
              "dsn": "PROD.BILLING.INPUT.CUSTMAST",
              "disp": ["SHR","KEEP","KEEP"],
              "gdg": false, "gdgBias": null,
              "sysout": null, "instream": false,
              "instreamLines": [0,0], "concat": false,
              "dcb": {}, "sms": {} },
            { "ddName": "BILLOUT",
              "dsn": "PROD.BILLING.OUTPUT",
              "disp": ["NEW","CATLG","DELETE"],
              "gdg": true, "gdgBias": "+1",
              "sysout": null, "instream": false,
              "instreamLines": [0,0], "concat": false,
              "dcb": { "recfm": "FB", "lrecl": 200, "blksize": 0 },
              "sms": {} },
            { "ddName": "WORKVSAM",
              "dsn": "PROD.BILLING.WORK",
              "disp": ["OLD","KEEP","KEEP"],
              "gdg": true, "gdgBias": "0",
              "sysout": null, "instream": false,
              "instreamLines": [0,0], "concat": false,
              "dcb": {}, "sms": {} },
            { "ddName": "ERRRPT",   "dsn": null,
              "disp": ["NEW","DELETE","DELETE"],
              "gdg": false, "gdgBias": null,
              "sysout": "*", "instream": false,
              "instreamLines": [0,0], "concat": false,
              "dcb": {}, "sms": {} }
          ]
        },
        {
          "stepName": "STEP030.COPYSTEP",
          "source": "proc:ARCHPROC",
          "program": "IEBGENER",
          "programDynamic": false,
          "steplib": [],
          "cond": null,
          "ifGuard": null,
          "chkpt": null,
          "ddStatements": [
            { "ddName": "SYSUT1",
              "dsn": "PROD.BILLING.OUTPUT",
              "disp": ["SHR","KEEP","KEEP"],
              "gdg": true, "gdgBias": "+1",
              "sysout": null, "instream": false,
              "instreamLines": [0,0], "concat": false,
              "dcb": {}, "sms": {} },
            { "ddName": "SYSUT2",
              "dsn": "PROD.BILLING.ARCHIVE",
              "disp": ["NEW","CATLG","DELETE"],
              "gdg": true, "gdgBias": "+1",
              "sysout": null, "instream": false,
              "instreamLines": [0,0], "concat": false,
              "dcb": {}, "sms": {} }
          ]
        },
        {
          "stepName": "STEP040",
          "source": "inline",
          "program": "DB2LOAD",
          "programDynamic": false,
          "steplib": ["PROD.DB2.LOADLIB"],
          "cond": "(0,NE,STEP020)",
          "ifGuard": "STEP020.RC = 0",
          "chkpt": null,
          "ddStatements": [
            { "ddName": "SYSREC",
              "dsn": "PROD.BILLING.OUTPUT",
              "disp": ["SHR","KEEP","KEEP"],
              "gdg": true, "gdgBias": "0",
              "sysout": null, "instream": false,
              "instreamLines": [0,0], "concat": false,
              "dcb": {}, "sms": {} }
          ]
        },
        {
          "stepName": "STEP041",
          "source": "inline",
          "program": "IEFBR14",
          "programDynamic": false,
          "steplib": [],
          "cond": null,
          "ifGuard": "NOT (STEP020.RC = 0)",
          "chkpt": null,
          "ddStatements": [
            { "ddName": "ABORTLOG", "dsn": null,
              "disp": ["NEW","DELETE","DELETE"],
              "gdg": false, "gdgBias": null,
              "sysout": "*", "instream": false,
              "instreamLines": [0,0], "concat": false,
              "dcb": {}, "sms": {} }
          ]
        },
        {
          "stepName": "STEP050",
          "source": "inline",
          "program": "IEBGENER",
          "programDynamic": false,
          "steplib": [],
          "cond": "(4,LT,STEP020)",
          "ifGuard": null,
          "chkpt": null,
          "ddStatements": [
            { "ddName": "SYSUT1",
              "dsn": "PROD.BILLING.OUTPUT",
              "disp": ["SHR","KEEP","KEEP"],
              "gdg": true, "gdgBias": "0",
              "sysout": null, "instream": false,
              "instreamLines": [0,0], "concat": false,
              "dcb": {}, "sms": {} }
          ]
        }
      ],
      "conditions": [
        { "kind": "IF",   "expr": "STEP020.RC = 0",
          "appliesTo": ["STEP040","STEP041"] },
        { "kind": "COND", "expr": "(0,NE,STEP020)",
          "appliesTo": ["STEP040"] },
        { "kind": "COND", "expr": "(4,LT,STEP020)",
          "appliesTo": ["STEP050"] }
      ]
    }
  ],
  "programs": [
    { "name": "BILL010",  "calledFrom": ["BILL010J.STEP020"], "dynamic": false },
    { "name": "DB2LOAD",  "calledFrom": ["BILL010J.STEP040"], "dynamic": false },
    { "name": "IDCAMS",   "calledFrom": ["BILL010J.STEP010"], "dynamic": false },
    { "name": "IEBGENER",
      "calledFrom": ["BILL010J.STEP030.COPYSTEP","BILL010J.STEP050"],
      "dynamic": false },
    { "name": "IEFBR14",  "calledFrom": ["BILL010J.STEP041"], "dynamic": false }
  ],
  "datasetEdges": [
    { "from": "BILL010J.STEP020", "to": "BILL010J.STEP030.COPYSTEP",
      "dsn": "PROD.BILLING.OUTPUT",
      "via": "DSN", "kind": "READ-AFTER-WRITE" },
    { "from": "BILL010J.STEP020", "to": "BILL010J.STEP040",
      "dsn": "PROD.BILLING.OUTPUT",
      "via": "DSN", "kind": "READ-AFTER-WRITE" },
    { "from": "BILL010J.STEP020", "to": "BILL010J.STEP050",
      "dsn": "PROD.BILLING.OUTPUT",
      "via": "DSN", "kind": "READ-AFTER-WRITE" }
  ],
  "metrics": {
    "jobsCount": 1,
    "stepsCount": 6,
    "programsCount": 5,
    "cyclomaticPerJob": { "BILL010J": 5 },
    "unresolvedProcs": 0,
    "unresolvedIncludes": 0,
    "dynamicProgramRefs": 0,
    "criticalPath": ["BILL010J.STEP020", "BILL010J.STEP040"]
  },
  "warnings": [],
  "chaining": {
    "styleProfileSeen": false,
    "profileSchemaVersion": "1.0"
  }
}
```

## `job-flow.md` (excerpt)

```markdown
# Job flow brief — BILL010J  (source: job-flow.json)

- Jobs: 1   Steps: 6   Distinct programs: 5
- Restart: STEP020   JOBLIB: PROD.LOADLIB, PROD.DB2.LOADLIB
- Critical path: BILL010J.STEP020 → BILL010J.STEP040
- Conditional branches: IF (STEP020.RC = 0) gates STEP040/STEP041;
  COND (4,LT,STEP020) gates STEP050.

## Top consumed datasets

1. PROD.BILLING.OUTPUT — 3 consumers (STEP030.COPYSTEP, STEP040, STEP050)
2. PROD.BILLING.WORK   — 1 consumer  (STEP020)
3. PROD.BILLING.INPUT.CUSTMAST — 1 consumer (STEP020)

## Producer → consumer chains

- STEP020 → STEP040 via PROD.BILLING.OUTPUT (load to DB2)
- STEP020 → STEP030.COPYSTEP via PROD.BILLING.OUTPUT (archive)
- STEP020 → STEP050 via PROD.BILLING.OUTPUT (print)

## Warnings

(none)
```

