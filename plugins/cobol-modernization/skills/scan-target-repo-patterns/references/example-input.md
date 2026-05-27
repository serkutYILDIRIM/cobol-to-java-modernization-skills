# Example input — `scan-target-repo-patterns`

The skill takes a **path** to a Java repository, not a file. The "input"
shown below is therefore a realistic snapshot of the destination repo
(`/workspace/acme-billing-service`) that the skill walks. Only the bits
the workflow actually reads are reproduced here.

## 1. Repo root layout

```
acme-billing-service/
├── .editorconfig
├── .gitattributes
├── .java-version                 # contents: 21
├── config/
│   └── checkstyle/
│       └── checkstyle.xml
├── pom.xml
├── src/
│   ├── main/
│   │   ├── java/com/acme/billing/
│   │   │   ├── BillingApplication.java
│   │   │   ├── customer/
│   │   │   │   ├── CustomerController.java
│   │   │   │   ├── CustomerService.java
│   │   │   │   ├── CustomerRepository.java
│   │   │   │   ├── Customer.java               // @Entity, no suffix
│   │   │   │   └── api/
│   │   │   │       ├── CustomerView.java       // public record CustomerView(...)
│   │   │   │       └── CreateCustomerRequest.java
│   │   │   ├── invoice/
│   │   │   │   ├── InvoiceController.java
│   │   │   │   ├── InvoiceService.java
│   │   │   │   ├── InvoiceRepository.java
│   │   │   │   ├── Invoice.java
│   │   │   │   └── mapper/InvoiceMapper.java   // MapStruct
│   │   │   └── common/
│   │   │       ├── AcmeException.java          // extends RuntimeException
│   │   │       └── GlobalExceptionHandler.java // @RestControllerAdvice
│   │   └── resources/
│   │       ├── application.yml
│   │       ├── application-dev.yml
│   │       ├── application-prod.yml
│   │       ├── application-test.yml
│   │       └── db/migration/V1__init.sql
│   └── test/
│       └── java/com/acme/billing/
│           ├── customer/CustomerServiceTest.java
│           ├── invoice/InvoiceControllerIT.java
│           └── arch/PackageRulesTest.java       // ArchUnit
└── target/                                      # excluded
```

## 2. `pom.xml` excerpt the skill parses

```xml
<project>
  <modelVersion>4.0.0</modelVersion>
  <parent>
    <groupId>org.springframework.boot</groupId>
    <artifactId>spring-boot-starter-parent</artifactId>
    <version>3.3.4</version>
  </parent>
  <groupId>com.acme</groupId>
  <artifactId>billing-service</artifactId>
  <version>2.7.0</version>

  <properties>
    <maven.compiler.release>21</maven.compiler.release>
    <project.build.sourceEncoding>UTF-8</project.build.sourceEncoding>
  </properties>

  <dependencies>
    <dependency><groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-web</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-data-jpa</artifactId></dependency>
    <dependency><groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-validation</artifactId></dependency>
    <dependency><groupId>org.flywaydb</groupId>
      <artifactId>flyway-core</artifactId></dependency>
    <dependency><groupId>org.mapstruct</groupId>
      <artifactId>mapstruct</artifactId><version>1.6.2</version></dependency>
    <dependency><groupId>org.springdoc</groupId>
      <artifactId>springdoc-openapi-starter-webmvc-ui</artifactId>
      <version>2.6.0</version></dependency>
    <dependency><groupId>org.springframework.boot</groupId>
      <artifactId>spring-boot-starter-test</artifactId><scope>test</scope></dependency>
    <dependency><groupId>org.testcontainers</groupId>
      <artifactId>postgresql</artifactId><scope>test</scope></dependency>
    <dependency><groupId>com.tngtech.archunit</groupId>
      <artifactId>archunit-junit5</artifactId><scope>test</scope></dependency>
  </dependencies>

  <build>
    <plugins>
      <plugin><groupId>com.diffplug.spotless</groupId>
        <artifactId>spotless-maven-plugin</artifactId>
        <configuration>
          <java><palantirJavaFormat/></java>
        </configuration>
      </plugin>
      <plugin><groupId>com.github.spotbugs</groupId>
        <artifactId>spotbugs-maven-plugin</artifactId></plugin>
    </plugins>
  </build>
</project>
```

## 3. Representative source snippets the inference uses

`Customer.java` (drives `entitySuffix=""`,
`entityAnnotation=jakarta.persistence.Entity`):

```java
package com.acme.billing.customer;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;

@Entity
public class Customer {
    @Id private Long id;
    private String name;
    protected Customer() {}
    // ...getters only...
}
```

`CustomerView.java` (drives `dtoConvention.kind=record`, `dtoSuffix=""`):

```java
package com.acme.billing.customer.api;

import jakarta.validation.constraints.NotBlank;

public record CustomerView(@NotBlank String name, long lifetimeInvoices) {}
```

`GlobalExceptionHandler.java` (drives
`exceptionHandling.style=@RestControllerAdvice`):

```java
package com.acme.billing.common;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

@RestControllerAdvice
public class GlobalExceptionHandler {
    private static final Logger LOG = LoggerFactory.getLogger(GlobalExceptionHandler.class);
    @ExceptionHandler(AcmeException.class)
    public ProblemDetail handle(AcmeException ex) { /* ... */ }
}
```

`application.yml` (drives `configStrategy.primaryFile=application.yml`,
`profiles=[dev, prod, test]`).

## 4. Skill invocation

```bash
agent run scan-target-repo-patterns \
  --target_repo_path=/workspace/acme-billing-service \
  --out_dir=/workspace/_modernization/sidecars \
  --git_sha=4f2c1ab
```

