package com.iem.admin.dto;

import java.util.List;

public record SystemHealthResponse(String checkedAt, List<Service> services) {

    public record Service(String name, String detail, String status, Long latencyMs, String note) {
    }
}
