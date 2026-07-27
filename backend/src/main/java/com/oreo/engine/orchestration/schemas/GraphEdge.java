package com.oreo.engine.orchestration.schemas;

import lombok.Data;

@Data
public class GraphEdge {
    private String from;
    private String to;

    public GraphEdge() {}

    public GraphEdge(String from, String to) {
        this.from = from;
        this.to = to;
    }
}
