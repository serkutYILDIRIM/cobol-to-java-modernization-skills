# Example input — `transpile-cobol-to-java21`

The transpiler is fed by **four** upstream JSON artefacts plus the raw COBOL
source. Excerpts of each are shown below for the program `BILL010`.

## 1. COBOL source slice — `src/cobol/BILL010.cob`

```cobol
       IDENTIFICATION DIVISION.
       PROGRAM-ID. BILL010.
       DATA DIVISION.
       WORKING-STORAGE SECTION.
       01  WS-FLAGS.
           05 WS-CUST-STATUS    PIC X(01).
              88 WS-ACTIVE      VALUE 'A'.
              88 WS-SUSPENDED   VALUE 'S'.
       01  WS-CHARGE            PIC S9(7)V99 COMP-3.
       LINKAGE SECTION.
       01  LK-BILL-INPUT.
           COPY BILLREC.
       PROCEDURE DIVISION USING LK-BILL-INPUT.
       0000-MAIN SECTION.
           PERFORM 1000-VALIDATE-CUSTOMER
           IF WS-ACTIVE
              PERFORM 2000-CALC-CHARGES
           END-IF
           GOBACK.
       1000-VALIDATE-CUSTOMER SECTION.
           EVALUATE TRUE
             WHEN LK-CUST-ID = SPACES
                MOVE 'S' TO WS-CUST-STATUS
             WHEN LK-BALANCE < 0
                MOVE 'S' TO WS-CUST-STATUS
             WHEN OTHER
                MOVE 'A' TO WS-CUST-STATUS
           END-EVALUATE.
       2000-CALC-CHARGES SECTION.
           COMPUTE WS-CHARGE =
               LK-BALANCE * 0.015 ROUNDED.
           EXEC SQL
              UPDATE BILLDB.CUSTOMER
                 SET LAST_CHARGE = :WS-CHARGE
               WHERE CUST_ID    = :LK-CUST-ID
           END-EXEC.
```

## 2. `program-profile.json` (excerpt)

```json
{
  "schemaVersion": "1.0",
  "source": { "path": "src/cobol/BILL010.cob", "sha256": "REPLACE_WITH_SHA256" },
  "programId": "BILL010",
  "paragraphs": [
    { "name": "0000-MAIN",              "section": true,  "startLine": 14 },
    { "name": "1000-VALIDATE-CUSTOMER", "section": true,  "startLine": 21 },
    { "name": "2000-CALC-CHARGES",      "section": true,  "startLine": 30 }
  ],
  "controlFlow": {
    "evaluates": [
      { "paragraph": "1000-VALIDATE-CUSTOMER",
        "kind": "TRUE",
        "arms": ["LK-CUST-ID=SPACES", "LK-BALANCE<0", "OTHER"] }
    ]
  },
  "db2Tables":      [ { "schema": "BILLDB", "table": "CUSTOMER", "ops": ["UPDATE"] } ],
  "vsamDatasets":   [],
  "calls":          [],
  "linkage":        [ { "name": "LK-BILL-INPUT", "copy": "BILLREC" } ]
}
```

## 3. `business-rules.json` (excerpt)

```json
{
  "schemaVersion": "1.0",
  "source": { "path": "src/cobol/BILL010.cob", "sha256": "REPLACE_WITH_SHA256" },
  "rules": [
    { "id": "BR-BILLING-001", "groupId": "VALIDATE-CUSTOMER", "type": "VALIDATION",
      "trigger": { "head": "EVALUATE TRUE", "arm": "LK-CUST-ID = SPACES", "priority": 1 },
      "paragraph": "1000-VALIDATE-CUSTOMER", "startLine": 23,
      "dataItems": { "reads": ["LK-CUST-ID"], "writes": ["WS-CUST-STATUS"] },
      "confidence": 0.97, "reachable": true, "programExit": false },
    { "id": "BR-BILLING-002", "groupId": "VALIDATE-CUSTOMER", "type": "VALIDATION",
      "trigger": { "head": "EVALUATE TRUE", "arm": "LK-BALANCE < 0", "priority": 2 },
      "paragraph": "1000-VALIDATE-CUSTOMER", "startLine": 25,
      "dataItems": { "reads": ["LK-BALANCE"], "writes": ["WS-CUST-STATUS"] },
      "confidence": 0.97, "reachable": true, "programExit": false },
    { "id": "BR-BILLING-003", "groupId": "CALC-CHARGES", "type": "CALCULATION",
      "trigger": { "head": "COMPUTE", "arm": "WS-CHARGE = LK-BALANCE * 0.015", "priority": 1 },
      "paragraph": "2000-CALC-CHARGES", "startLine": 31,
      "dataItems": { "reads": ["LK-BALANCE"], "writes": ["WS-CHARGE"] },
      "confidence": 0.99, "reachable": true, "programExit": false },
    { "id": "BR-BILLING-004", "groupId": "CALC-CHARGES", "type": "IO-EFFECT",
      "trigger": { "head": "EXEC SQL", "arm": "UPDATE BILLDB.CUSTOMER", "priority": 2 },
      "paragraph": "2000-CALC-CHARGES", "startLine": 33,
      "dataItems": { "reads": ["WS-CHARGE","LK-CUST-ID"], "writes": ["BILLDB.CUSTOMER.LAST_CHARGE"] },
      "confidence": 0.95, "reachable": true, "programExit": false }
  ]
}
```

## 4. `copybook-mapping.json` (excerpt for BILLREC)

```json
{
  "schemaVersion": "1.0",
  "copybook": { "member": "BILLREC" },
  "javaPackage": "com.acme.billing.dto",
  "records": [
    { "javaName": "BillRecord", "javaFile": "com/acme/billing/dto/BillRecord.java",
      "fromCobolName": "LK-BILL-INPUT", "byteLength": 256,
      "fields": [
        { "javaName": "custId",  "javaType": "String",     "fromCobolName": "LK-CUST-ID",  "byteOffset": 0,  "byteLength": 10 },
        { "javaName": "balance", "javaType": "BigDecimal", "fromCobolName": "LK-BALANCE",  "byteOffset": 10, "byteLength": 9, "scale": 2 }
      ] }
  ]
}
```

## 5. `jpa-mapping.json` (excerpt)

```json
{
  "schemaVersion": "1.0",
  "entities": [
    { "javaName": "Customer", "javaFile": "com/acme/billing/persistence/Customer.java",
      "table": "CUSTOMER", "schema": "BILLDB",
      "idFields": [ { "javaName": "custId", "javaType": "String", "column": "CUST_ID" } ],
      "fields":   [ { "javaName": "lastCharge", "javaType": "BigDecimal", "column": "LAST_CHARGE", "scale": 2 } ],
      "repository": { "javaName": "CustomerRepository", "extends": "JpaRepository<Customer, String>" } }
  ]
}
```

## 6. `target-repo-style-profile.json` (excerpt)

```json
{
  "schemaVersion": "1.0",
  "buildTool": "maven",
  "javaVersion": "21",
  "packageLayout": {
    "rootPackage": "com.acme.billing",
    "servicesPackage": "com.acme.billing.legacy.bill010",
    "dtoPackage": "com.acme.billing.dto",
    "persistencePackage": "com.acme.billing.persistence"
  },
  "namingConventions": { "serviceSuffix": "Service", "exceptionSuffix": "Exception" },
  "loggingStack": "slf4j",
  "exceptionHandling": "checked-domain-then-runtime-at-boundary"
}
```

