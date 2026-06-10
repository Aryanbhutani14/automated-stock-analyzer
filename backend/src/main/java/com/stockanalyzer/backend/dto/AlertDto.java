package com.stockanalyzer.backend.dto;

import java.time.LocalDateTime;

public class AlertDto {
    private Long id;
    private String symbol;
    private String name;
    private String alertType;
    private Double threshold;
    private boolean active;
    private LocalDateTime lastTriggered;
    private LocalDateTime createdAt;

    public AlertDto() {}

    public AlertDto(Long id, String symbol, String name, String alertType, Double threshold,
                    boolean active, LocalDateTime lastTriggered, LocalDateTime createdAt) {
        this.id = id;
        this.symbol = symbol;
        this.name = name;
        this.alertType = alertType;
        this.threshold = threshold;
        this.active = active;
        this.lastTriggered = lastTriggered;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getSymbol() { return symbol; }
    public void setSymbol(String symbol) { this.symbol = symbol; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getAlertType() { return alertType; }
    public void setAlertType(String alertType) { this.alertType = alertType; }

    public Double getThreshold() { return threshold; }
    public void setThreshold(Double threshold) { this.threshold = threshold; }

    public boolean isActive() { return active; }
    public void setActive(boolean active) { this.active = active; }

    public LocalDateTime getLastTriggered() { return lastTriggered; }
    public void setLastTriggered(LocalDateTime lastTriggered) { this.lastTriggered = lastTriggered; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
