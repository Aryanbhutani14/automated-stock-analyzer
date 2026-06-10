package com.stockanalyzer.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;

public class CreateAlertRequest {

    @NotBlank
    private String symbol;

    @NotBlank
    private String alertType;

    private Double threshold;

    public CreateAlertRequest() {}

    public CreateAlertRequest(String symbol, String alertType, Double threshold) {
        this.symbol = symbol;
        this.alertType = alertType;
        this.threshold = threshold;
    }

    public String getSymbol() { return symbol; }
    public void setSymbol(String symbol) { this.symbol = symbol; }

    public String getAlertType() { return alertType; }
    public void setAlertType(String alertType) { this.alertType = alertType; }

    public Double getThreshold() { return threshold; }
    public void setThreshold(Double threshold) { this.threshold = threshold; }
}
