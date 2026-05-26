package com.acme.billing.customer;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;
import java.math.BigDecimal;

@Entity
public class Customer {

    @Id
    private Long id;

    private String name;

    private BigDecimal lifetimeCharges;

    protected Customer() {
        // for JPA
    }

    public Customer(Long id, String name, BigDecimal lifetimeCharges) {
        this.id = id;
        this.name = name;
        this.lifetimeCharges = lifetimeCharges;
    }

    public Long getId() {
        return id;
    }

    public String getName() {
        return name;
    }

    public BigDecimal getLifetimeCharges() {
        return lifetimeCharges;
    }
}

