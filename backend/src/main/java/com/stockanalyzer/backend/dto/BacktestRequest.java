package com.stockanalyzer.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import java.time.LocalDate;

public class BacktestRequest {

    @NotBlank
    private String strategyName;

    @NotBlank
    private String symbol;

    @NotNull
    private LocalDate startDate;

    @NotNull
    private LocalDate endDate;

    private Double initialCapital = 100000.0;

    public BacktestRequest() {}

    public BacktestRequest(String strategyName, String symbol, LocalDate startDate, LocalDate endDate, Double initialCapital) {
        this.strategyName = strategyName;
        this.symbol = symbol;
        this.startDate = startDate;
        this.endDate = endDate;
        this.initialCapital = initialCapital;
    }

    public String getStrategyName() { return strategyName; }
    public void setStrategyName(String strategyName) { this.strategyName = strategyName; }

    public String getSymbol() { return symbol; }
    public void setSymbol(String symbol) { this.symbol = symbol; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public Double getInitialCapital() { return initialCapital; }
    public void setInitialCapital(Double initialCapital) { this.initialCapital = initialCapital; }
}
