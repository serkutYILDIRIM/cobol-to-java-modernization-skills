PHASE 0 — ONE-TIME REPOSITORY PROFILING

Goal: Produce `.copilot-conversion/STATE/repo-profile.md` so every future
conversion follows the repo's house style without re-asking.

STEP A — SCAN. Inspect the workspace and extract:

  1. Build & runtime
     - Build tool (Maven / Gradle), exact version
     - Java version (from pom.xml or build.gradle toolchain)
     - Spring Boot version, key starter dependencies
     - Any BOM or platform constraints

  2. Package layout & module structure
     - Root package (e.g., com.acme.payroll)
     - Sub-package convention per layer
     - Multi-module? Spring Modulith? Hexagonal? Layered? Onion?

  3. Naming conventions
     - Controller / Service / Repository / Entity / DTO / Mapper suffixes
     - Record vs class usage for DTOs
     - Configuration class naming (`*Config`, `*Properties`)

  4. Persistence stack
     - JPA/Hibernate, jOOQ, MyBatis, R2DBC, JDBC?
     - Entity annotations style (field vs property access)
     - Repository interface naming
     - Migration tool (Flyway/Liquibase) + folder location

  5. API style
     - REST + Spring MVC or WebFlux?
     - OpenAPI generation? Manual annotations? Controllers per resource?
     - Request/response DTO conventions, validation annotations used

  6. Exception handling
     - Custom exception hierarchy? `@ControllerAdvice` location?
     - Error response shape (RFC 7807? Custom?)

  7. Logging & observability
     - SLF4J + which backend? Structured JSON logs?
     - Tracing/metrics: Micrometer? OpenTelemetry?

  8. Testing stack
     - JUnit version, AssertJ/Hamcrest, Mockito version
     - Testcontainers? ArchUnit? Pact?
     - Integration test naming and location (`*IT`, `*IntegrationTest`)
     - Test slice annotations used (`@DataJpaTest`, `@WebMvcTest`, etc.)

  9. Configuration
     - `application.yml` vs `application.properties`
     - Profile strategy (dev/staging/prod)
     - `@ConfigurationProperties` usage

 10. Code style
     - Checkstyle / Spotless / Spotbugs configs (look for files)
     - Lombok used? If yes, which annotations are preferred?
     - MapStruct used? Mapper interface conventions

 11. Domain glossary
     - Skim domain packages and list 10–20 key domain terms with
       their canonical Java types (e.g., Money → BigDecimal scale 4,
       EmployeeId → record wrapping Long).

STEP B — ASK FIRST.
If anything is ambiguous (e.g., two different naming patterns coexist),
ASK the user up to 5 numbered questions before writing the profile.

STEP C — WRITE THE PROFILE.
Create `.copilot-conversion/STATE/repo-profile.md` containing every
section above with CONCRETE values and concrete file path references
(`see src/main/java/com/acme/.../FooService.java for canonical example`).

STEP D — DO NOT COMMIT. Only write the file. End with a one-line
summary of the most important conventions in chat so the user can
sanity-check.