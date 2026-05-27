package com.acme.billing.customer;

import org.junit.jupiter.api.Test;
import org.mockito.Mockito;

import java.util.List;

import static org.assertj.core.api.Assertions.assertThat;

class CustomerServiceTest {

    @Test
    void listAll_returnsViews() {
        CustomerRepository repo = Mockito.mock(CustomerRepository.class);
        Mockito.when(repo.findAll()).thenReturn(List.of());

        CustomerService svc = new CustomerService(repo);

        assertThat(svc.listAll()).isEmpty();
    }
}

