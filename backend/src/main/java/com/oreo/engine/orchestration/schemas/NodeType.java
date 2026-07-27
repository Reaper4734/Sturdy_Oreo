package com.oreo.engine.orchestration.schemas;

import com.fasterxml.jackson.annotation.JsonCreator;
import com.fasterxml.jackson.annotation.JsonValue;

public enum NodeType {
    SECTION("section"),
    TOPIC("topic"),
    PROJECT("project"),
    ASSESSMENT("assessment"),
    CAPSTONE("capstone");

    private final String value;

    NodeType(String value) {
        this.value = value;
    }

    @JsonValue
    public String getValue() {
        return value;
    }

    @JsonCreator
    public static NodeType fromValue(String value) {
        for (NodeType type : NodeType.values()) {
            if (type.value.equalsIgnoreCase(value)) {
                return type;
            }
        }
        return TOPIC; // Default fallback
    }
}
