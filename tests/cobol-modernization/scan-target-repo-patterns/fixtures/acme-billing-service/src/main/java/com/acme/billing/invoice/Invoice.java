package com.acme.billing.invoice;

import jakarta.persistence.Entity;
import jakarta.persistence.Id;

import java.math.BigDecimal;
import java.time.LocalDate;

@Entity
public class Invoice {

    @Id
    private Long id;

    private Long customerId;

    private LocalDate invoiceDate;

    private BigDecimal amount;

    protected Invoice() {}

    public Long getId() { return id; }
    public Long getCustomerId() { return customerId; }
    public LocalDate getInvoiceDate() { return invoiceDate; }
    public BigDecimal getAmount() { return amount; }
}

