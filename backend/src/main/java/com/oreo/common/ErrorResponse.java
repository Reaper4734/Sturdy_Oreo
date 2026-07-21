package com.oreo.common;

import java.time.LocalDateTime;

public record ErrorResponse(
        String error,
        String message,
        LocalDateTime timestamp,
        String traceId
) {
    public ErrorResponse(String error, String message) {
        this(error, message, LocalDateTime.now(), java.util.UUID.randomUUID().toString().substring(0, 8));
    }
}
