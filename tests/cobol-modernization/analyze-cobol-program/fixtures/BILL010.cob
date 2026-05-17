       IDENTIFICATION DIVISION.
       PROGRAM-ID. BILL010.
       AUTHOR. MODERNIZATION-TEAM.
       DATE-WRITTEN. 1998-03-12.
      *>====================================================
      *> Monthly billing engine for retail postpaid customers.
      *> Reads CUST-MASTER (VSAM KSDS), applies plan-specific
      *> tariffs, looks up tax rate from DB2, writes BILL-OUT.
      *>====================================================
       ENVIRONMENT DIVISION.
       INPUT-OUTPUT SECTION.
       FILE-CONTROL.
           SELECT CUST-MASTER ASSIGN TO CUSTMSTR
               ORGANIZATION IS INDEXED
               ACCESS MODE IS DYNAMIC
               RECORD KEY IS CM-CUST-ID
               FILE STATUS IS WS-CM-STATUS.
           SELECT BILL-OUT    ASSIGN TO BILLOUT
               ORGANIZATION IS SEQUENTIAL
               FILE STATUS IS WS-BO-STATUS.

       DATA DIVISION.
       FILE SECTION.
       FD  CUST-MASTER.
       01  CUST-MASTER-REC.
           COPY CUSTREC REPLACING ==:PFX:== BY ==CM==.
       FD  BILL-OUT
           RECORDING MODE IS F
           BLOCK CONTAINS 0 RECORDS.
       01  BILL-OUT-REC               PIC X(200).

       WORKING-STORAGE SECTION.
       01  WS-CM-STATUS               PIC XX VALUE '00'.
       01  WS-BO-STATUS               PIC XX VALUE '00'.
       01  WS-EOF-FLAG                PIC X  VALUE 'N'.
           88 WS-EOF                  VALUE 'Y'.
       01  WS-COUNTERS.
           05 WS-READ-CT              PIC S9(7) COMP-3 VALUE 0.
           05 WS-BILLED-CT            PIC S9(7) COMP-3 VALUE 0.
           05 WS-ERROR-CT             PIC S9(7) COMP-3 VALUE 0.
       01  WS-AMOUNTS.
           05 WS-BASE-AMT             PIC S9(7)V99 COMP-3.
           05 WS-TAX-PCT              PIC S9(3)V99 COMP-3.
           05 WS-TOTAL-AMT            PIC S9(7)V99 COMP-3.
       01  WS-RATE-TBL.
           05 WS-RATE-ROW OCCURS 12 TIMES
                          INDEXED BY RT-IX.
              10 WS-RATE-MONTH        PIC 9(2).
              10 WS-RATE-VALUE        PIC S9(3)V99 COMP-3.
       01  WS-RATE-RAW REDEFINES WS-RATE-TBL PIC X(60).
       01  WS-MONTH-IX                PIC 9(2)     COMP.

       LINKAGE SECTION.
       01  LK-RUN-DATE                PIC 9(8).
       01  LK-RETURN-CODE             PIC S9(4) COMP.

       PROCEDURE DIVISION USING LK-RUN-DATE
                                LK-RETURN-CODE.
       0000-MAIN SECTION.
           PERFORM 1000-INIT
           PERFORM 2000-PROCESS UNTIL WS-EOF
           PERFORM 9000-TERM
           MOVE 0 TO LK-RETURN-CODE
           GOBACK.

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

       2000-PROCESS SECTION.
           READ CUST-MASTER NEXT
              AT END SET WS-EOF TO TRUE
           END-READ
           IF NOT WS-EOF
              ADD 1 TO WS-READ-CT
              PERFORM 2100-COMPUTE-BILL
              PERFORM 2200-WRITE-BILL
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

       2200-WRITE-BILL SECTION.
           CALL 'BILLFMT' USING CM-CUST-ID
                                WS-TOTAL-AMT
                                BILL-OUT-REC
           WRITE BILL-OUT-REC
           ADD 1 TO WS-BILLED-CT.

       9000-TERM SECTION.
           CLOSE CUST-MASTER BILL-OUT
           DISPLAY 'READ='   WS-READ-CT
                   ' BILLED=' WS-BILLED-CT
                   ' ERR='   WS-ERROR-CT.

