      ******************************************************************
      * RESERVED.CPY  --  Tests Java-reserved-word handling and field
      *                   name collisions inside a single 01 group.
      ******************************************************************
       01  SAMPLE-REC.
           05  CLASS                       PIC X(10).
           05  AMOUNT                      PIC S9(7)V99 COMP-3.
           05  AMOUNT-LINE.
               10  AMOUNT                  PIC S9(5)V99 COMP-3.
               10  CURRENCY                PIC X(3).
           05  ENUM-FLAG                   PIC X(1).
               88  ENUM-FLAG-ON            VALUE 'Y'.
               88  ENUM-FLAG-OFF           VALUE 'N'.
           05  FILLER                      PIC X(20).

