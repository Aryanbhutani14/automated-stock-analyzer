package com.stockanalyzer.backend.dto;

import jakarta.validation.constraints.NotBlank;

public class AddStockRequest {

    @NotBlank
    private String symbol;

    public AddStockRequest() {}

    public AddStockRequest(String symbol) {
        this.symbol = symbol;
    }

    public String getSymbol() { return symbol; }
    public void setSymbol(String symbol) { this.symbol = symbol; }
}
