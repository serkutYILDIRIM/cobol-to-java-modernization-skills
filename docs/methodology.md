# Methodology

> Stub. Full content will be filled in Phase 5.

## Table of contents

1. Introduction — why a skill-based approach for COBOL modernization
2. The 6 phases of building this skill catalog
3. Reference architectures
   1. Source side: COBOL / CICS / IMS / DB2 / VSAM topology
   2. Target side: Java 21 + Spring Boot 3.x topology
4. Pipeline composition
   1. Discovery (`scan-target-repo-patterns`)
   2. Analysis (`analyze-cobol-program`, `extract-cobol-business-rules`,
      `map-mainframe-job-flow`)
   3. Visualization (`diagram-cobol-with-mermaid`)
   4. Conversion (`convert-copybook-to-java-record`, `map-vsam-db2-to-jpa`,
      `transpile-cobol-to-java21`)
   5. Planning (`plan-strangler-fig-migration`)
   6. Verification (`generate-modernization-tests`)
5. Modernization patterns applied
   1. Strangler Fig
   2. Branch by Abstraction
   3. Anti-Corruption Layer
   4. Characterization testing
6. Data-fidelity concerns
   1. COMP-3 packed-decimal scaling and signs
   2. REDEFINES and unions
   3. OCCURS DEPENDING ON and dynamic arrays
   4. EBCDIC ↔ UTF-8 conversions
7. Migration governance
8. Glossary
9. References

