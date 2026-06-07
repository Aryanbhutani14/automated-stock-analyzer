package com.stockanalyzer.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Data;

@Data
public class CreateWatchlistRequest {

    @NotBlank(message = "Watchlist name is required")
    @Size(max = 100, message = "Name must be 100 characters or less")
    private String name;

    private String description;
}
