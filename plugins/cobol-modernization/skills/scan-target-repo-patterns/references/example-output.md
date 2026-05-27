# Example output — `scan-target-repo-patterns`

Two files are produced under `--out_dir`:

1. `target-repo-style-profile.json` — the canonical sidecar.
2. `style-profile-review.md` — short reviewer note.

## 1. `target-repo-style-profile.json` (complete)

```json
{
  "schemaVersion": "1.0",
  "source": {
    "repoPath": "/workspace/acme-billing-service",
    "gitSha": "4f2c1ab",
    "sampledJavaFiles": 47,
    "totalJavaFiles": 47,
    "totalJavaSloc": 3142
  },
  "buildTool": "maven",
  "javaVersion": "21",
  "rootPackage": "com.acme.billing",
  "packageLayout": "feature-sliced",
  "architectureStyle": "feature-sliced-mvc",
  "namingConventions": {
    "entitySuffix": "",
    "repositorySuffix": "Repository",
    "serviceSuffix": "Service",
    "useServiceInterface": false,
    "controllerSuffix": "Controller",
    "dtoSuffix": "",
    "mapperSuffix": "Mapper",
    "testSuffix": "Test",
    "itTestSuffix": "IT"
  },
  "dtoConvention": {
    "kind": "record",
    "nullPolicy": "non-null-by-default",
    "validation": "jakarta-validation",
    "serialization": "jackson"
  },
  "exceptionHandling": {
    "baseExceptionClass": "com.acme.billing.common.AcmeException",
    "style": "@RestControllerAdvice",
    "checkedVsUnchecked": "unchecked"
  },
  "loggingStack": {
    "facade": "slf4j",
    "declaration": "static-final",
    "backend": "logback"
  },
  "testStack": {
    "junit": "junit5",
    "assertions": "assertj",
    "mocking": "mockito",
    "integration": ["spring-boot-test", "testcontainers"],
    "archUnit": true
  },
  "apiStyle": {
    "kind": "spring-mvc",
    "openapiPlugin": "springdoc-openapi"
  },
  "persistenceStack": {
    "kind": "spring-data-jpa",
    "entityAnnotation": "jakarta.persistence.Entity",
    "txManagement": "spring-tx",
    "flywayOrLiquibase": "flyway"
  },
  "configStrategy": {
    "primaryFile": "application.yml",
    "configPropertiesCount": 4,
    "valueAnnotationCount": 1,
    "profiles": ["dev", "prod", "test"]
  },
  "codeStyleConfig": {
    "editorconfig": true,
    "checkstyle": "config/checkstyle/checkstyle.xml",
    "spotless": true,
    "googleJavaFormat": false,
    "palantirJavaFormat": true,
    "pmd": false,
    "spotbugs": true,
    "indentation": "4-space",
    "lineEnding": "lf"
  },
  "warnings": []
}
```

## 2. `style-profile-review.md` (complete)

```markdown
# Style Profile Review — acme-billing-service

## TL;DR
Feature-sliced Spring Boot 3.3 / Java 21 / Maven service. JPA on Postgres
via Flyway. DTOs are Java 21 records with jakarta-validation. Tests use
JUnit 5 + AssertJ + Mockito + Spring Boot Test + Testcontainers, plus
ArchUnit guards. Lint: Spotless + Palantir Java Format + SpotBugs +
Checkstyle. No Lombok detected.

## Top-line decisions downstream skills will follow

| Aspect             | Value                              |
|--------------------|------------------------------------|
| Root package       | `com.acme.billing`                 |
| Layout             | feature-sliced (1 package / aggregate) |
| DTO kind           | `public record …`                  |
| Entity suffix      | _(none — class `Customer`, not `CustomerEntity`)_ |
| Repository suffix  | `Repository` (Spring Data JPA)     |
| Exception base     | `com.acme.billing.common.AcmeException` (unchecked) |
| Advice style       | `@RestControllerAdvice` + `ProblemDetail` |
| Logger             | `private static final Logger LOG = LoggerFactory.getLogger(...)` |
| Indent             | 4 spaces, LF line endings          |

## Warnings
_(none)_

## How downstream skills will use this
- `convert-copybook-to-java-record` will emit records into
  `com.acme.billing.<feature>.api`, with `jakarta.validation`
  annotations and no DTO suffix.
- `map-vsam-db2-to-jpa` will emit `@Entity` classes under
  `com.acme.billing.<feature>` with the bare aggregate name
  (`Customer`, not `CustomerEntity`) and `*Repository` interfaces
  extending `JpaRepository`.
- `transpile-cobol-to-java21` will emit `@Service` classes ending in
  `Service` (no interface split), use SLF4J static-final loggers, throw
  `AcmeException` subtypes, and rely on the existing
  `GlobalExceptionHandler`.
- `generate-modernization-tests` will produce JUnit 5 + AssertJ +
  Mockito unit tests and `*IT.java` Testcontainers integration tests.
- `plan-strangler-fig-migration` will route through Spring MVC with
  springdoc-openapi for the published façade.
```

## Counter-example (greenfield / empty repo)

If `target_repo_path` exists but contains no Java sources, the skill
hard-fails with:

```
E-NO-JAVA-SOURCES: src/main/java contains 0 Java files at /workspace/empty-repo
```

The user can re-run with `--force_defaults=true` to emit the built-in
default profile (Spring Boot 3 + Java 21 + Maven + JPA + SLF4J +
JUnit 5 + AssertJ + Mockito + records + @RestControllerAdvice), which
sets `warnings: ["W-JAVA-VERSION-INFERRED", "W-NO-TESTS"]` and
`source.totalJavaFiles: 0`.

