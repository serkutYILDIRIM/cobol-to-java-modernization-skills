package com.acme.billing.customer.api;

import jakarta.validation.constraints.NotBlank;

public record CustomerView(@NotBlank String name, long lifetimeInvoices) {}

