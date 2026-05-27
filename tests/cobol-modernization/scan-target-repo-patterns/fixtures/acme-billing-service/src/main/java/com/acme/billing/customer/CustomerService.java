package com.acme.billing.customer;

import com.acme.billing.customer.api.CustomerView;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@Transactional
public class CustomerService {

    private static final Logger LOG = LoggerFactory.getLogger(CustomerService.class);

    private final CustomerRepository customers;

    public CustomerService(CustomerRepository customers) {
        this.customers = customers;
    }

    @Transactional(readOnly = true)
    public List<CustomerView> listAll() {
        LOG.debug("Listing all customers");
        return customers.findAll().stream()
                .map(c -> new CustomerView(c.getName(), 0L))
                .toList();
    }
}

