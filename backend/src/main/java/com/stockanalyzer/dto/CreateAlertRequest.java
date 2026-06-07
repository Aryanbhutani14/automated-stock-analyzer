package com.stockanalyzer.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class CreateAlertRequest {

    @NotBlank(message = "Stock symbol is required")
    private String symbol;

    @NotBlank(message = "Alert type is required")
    private String alertType;

    // Optional — required only for PRICE_ABOVE / PRICE_BELOW
    private BigDecimal threshold;
}
