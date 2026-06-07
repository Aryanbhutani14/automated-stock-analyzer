package com.stockanalyzer.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class AddStockRequest {

    @NotBlank(message = "Stock symbol is required")
    private String symbol;
}
