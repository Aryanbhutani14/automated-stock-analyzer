package com.stockanalyzer.backend.dto;

import java.time.LocalDate;

public class TradeLogDto {
    private String type; // BUY or SELL
    private LocalDate date;
    private Double price;
    private Double shares;
    private Double value;
    private Double profitPct; // for SELL trades

    public TradeLogDto() {}

    public TradeLogDto(String type, LocalDate date, Double price, Double shares, Double value, Double profitPct) {
        this.type = type;
        this.date = date;
        this.price = price;
        this.shares = shares;
        this.value = value;
        this.profitPct = profitPct;
    }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }

    public Double getPrice() { return price; }
    public void setPrice(Double price) { this.price = price; }

    public Double getShares() { return shares; }
    public void setShares(Double shares) { this.shares = shares; }

    public Double getValue() { return value; }
    public void setValue(Double value) { this.value = value; }

    public Double getProfitPct() { return profitPct; }
    public void setProfitPct(Double profitPct) { this.profitPct = profitPct; }
}
