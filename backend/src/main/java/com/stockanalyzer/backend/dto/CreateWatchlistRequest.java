package com.stockanalyzer.backend.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;

public class CreateWatchlistRequest {

    @NotBlank
    @Size(max = 100)
    private String name;

    private String description;

    public CreateWatchlistRequest() {}

    public CreateWatchlistRequest(String name, String description) {
        this.name = name;
        this.description = description;
    }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
}
