package com.stockanalyzer.backend.dto;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class WatchlistDto {
    private Long id;
    private String name;
    private String description;
    private List<StockDto> stocks = new ArrayList<>();
    private LocalDateTime createdAt;

    public WatchlistDto() {}

    public WatchlistDto(Long id, String name, String description, List<StockDto> stocks, LocalDateTime createdAt) {
        this.id = id;
        this.name = name;
        this.description = description;
        this.stocks = stocks;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public List<StockDto> getStocks() { return stocks; }
    public void setStocks(List<StockDto> stocks) { this.stocks = stocks; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
