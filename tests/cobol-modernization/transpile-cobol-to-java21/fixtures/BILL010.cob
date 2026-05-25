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

