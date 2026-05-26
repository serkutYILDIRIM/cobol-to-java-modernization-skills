package com.acme.billing.common;

public class AcmeException extends RuntimeException {
    public AcmeException(String message) {
        super(message);
    }

    public AcmeException(String message, Throwable cause) {
        super(message, cause);
    }
}

