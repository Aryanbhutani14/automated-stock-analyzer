package com.stockanalyzer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
public class BacktestRequest {

    @NotBlank(message = "Stock symbol is required")
    private String symbol;

    // Optional — null means test ALL strategies
    private String strategy;

    @NotNull(message = "Start date is required")
    private LocalDate startDate;

    @NotNull(message = "End date is required")
    private LocalDate endDate;

    private BigDecimal initialCapital = new BigDecimal("100000");
}
