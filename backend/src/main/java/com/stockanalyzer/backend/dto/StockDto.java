package com.stockanalyzer.backend.dto;

public class StockDto {
    private Long id;
    private String symbol;
    private String name;
    private String exchange;
    private String sector;
    private String industry;
    private Double price;
    private Double change;
    private Double changePercent;
    private Long volume;

    public StockDto() {}

    public StockDto(Long id, String symbol, String name, String exchange, String sector, String industry,
                    Double price, Double change, Double changePercent, Long volume) {
        this.id = id;
        this.symbol = symbol;
        this.name = name;
        this.exchange = exchange;
        this.sector = sector;
        this.industry = industry;
        this.price = price;
        this.change = change;
        this.changePercent = changePercent;
        this.volume = volume;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getSymbol() { return symbol; }
    public void setSymbol(String symbol) { this.symbol = symbol; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getExchange() { return exchange; }
    public void setExchange(String exchange) { this.exchange = exchange; }

    public String getSector() { return sector; }
    public void setSector(String sector) { this.sector = sector; }

    public String getIndustry() { return industry; }
    public void setIndustry(String industry) { this.industry = industry; }

    public Double getPrice() { return price; }
    public void setPrice(Double price) { this.price = price; }

    public Double getChange() { return change; }
    public void setChange(Double change) { this.change = change; }

    public Double getChangePercent() { return changePercent; }
    public void setChangePercent(Double changePercent) { this.changePercent = changePercent; }

    public Long getVolume() { return volume; }
    public void setVolume(Long volume) { this.volume = volume; }
}
