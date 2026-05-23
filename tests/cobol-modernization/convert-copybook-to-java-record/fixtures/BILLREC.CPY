      ******************************************************************
      * BILLREC.CPY  --  Billing record layout used by BILL010.
      *                  Fixed-length 256-byte record on VSAM KSDS.
      *                  Host encoding: IBM-1047 (EBCDIC US).
      ******************************************************************
       01  BILL-REC.
           05  BILL-KEY.
               10  BILL-CUST-ID            PIC S9(10) COMP.
               10  BILL-CYCLE-YYYYMM       PIC 9(6).
           05  BILL-CUST-NAME              PIC X(30).
           05  BILL-CUST-STATUS            PIC X(1).
               88  BILL-STATUS-ACTIVE      VALUE 'A'.
               88  BILL-STATUS-SUSPENDED   VALUE 'S'.
               88  BILL-STATUS-CLOSED      VALUE 'C' 'X'.
           05  BILL-CHARGES.
               10  BILL-CHARGE-COUNT       PIC S9(4) COMP.
               10  BILL-CHARGE-ITEM        OCCURS 1 TO 12 TIMES
                                           DEPENDING ON BILL-CHARGE-COUNT.
                   15  BILL-CHARGE-CODE    PIC X(4).
                   15  BILL-CHARGE-AMT     PIC S9(7)V99 COMP-3.
                   15  BILL-CHARGE-DATE    PIC 9(8).
           05  BILL-ADDR-AREA.
               10  BILL-ADDR-DOMESTIC.
                   15  BILL-ADDR-LINE1     PIC X(30).
                   15  BILL-ADDR-LINE2     PIC X(30).
                   15  BILL-ADDR-CITY      PIC X(20).
                   15  BILL-ADDR-STATE     PIC X(2).
                   15  BILL-ADDR-ZIP       PIC X(10).
                   15  FILLER              PIC X(8).
               10  BILL-ADDR-INTL REDEFINES BILL-ADDR-DOMESTIC.
                   15  BILL-ADDR-INTL-LN1  PIC X(35).
                   15  BILL-ADDR-INTL-LN2 PIC X(35).
                   15  BILL-ADDR-COUNTRY   PIC X(30).
           05  BILL-TOTAL-DUE              PIC S9(9)V99 COMP-3.
           05  BILL-DISPLAY-AMT            PIC $$,$$$,$$9.99CR.
           05  BILL-LAST-UPDATE-TS         PIC X(26).
           05  FILLER                      PIC X(31).

