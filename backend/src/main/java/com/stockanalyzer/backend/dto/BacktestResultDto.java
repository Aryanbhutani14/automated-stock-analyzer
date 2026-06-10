package com.stockanalyzer.backend.dto;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

public class BacktestResultDto {
    private Long id;
    private String strategyName;
    private String symbol;
    private LocalDate startDate;
    private LocalDate endDate;
    private Double totalReturnPct;
    private Double winRatePct;
    private Integer totalTrades;
    private Double maxDrawdownPct;
    private List<TradeLogDto> trades = new ArrayList<>();
    private LocalDateTime createdAt;

    public BacktestResultDto() {}

    public BacktestResultDto(Long id, String strategyName, String symbol, LocalDate startDate, LocalDate endDate,
                             Double totalReturnPct, Double winRatePct, Integer totalTrades, Double maxDrawdownPct,
                             List<TradeLogDto> trades, LocalDateTime createdAt) {
        this.id = id;
        this.strategyName = strategyName;
        this.symbol = symbol;
        this.startDate = startDate;
        this.endDate = endDate;
        this.totalReturnPct = totalReturnPct;
        this.winRatePct = winRatePct;
        this.totalTrades = totalTrades;
        this.maxDrawdownPct = maxDrawdownPct;
        this.trades = trades;
        this.createdAt = createdAt;
    }

    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public String getStrategyName() { return strategyName; }
    public void setStrategyName(String strategyName) { this.strategyName = strategyName; }

    public String getSymbol() { return symbol; }
    public void setSymbol(String symbol) { this.symbol = symbol; }

    public LocalDate getStartDate() { return startDate; }
    public void setStartDate(LocalDate startDate) { this.startDate = startDate; }

    public LocalDate getEndDate() { return endDate; }
    public void setEndDate(LocalDate endDate) { this.endDate = endDate; }

    public Double getTotalReturnPct() { return totalReturnPct; }
    public void setTotalReturnPct(Double totalReturnPct) { this.totalReturnPct = totalReturnPct; }

    public Double getWinRatePct() { return winRatePct; }
    public void setWinRatePct(Double winRatePct) { this.winRatePct = winRatePct; }

    public Integer getTotalTrades() { return totalTrades; }
    public void setTotalTrades(Integer totalTrades) { this.totalTrades = totalTrades; }

    public Double getMaxDrawdownPct() { return maxDrawdownPct; }
    public void setMaxDrawdownPct(Double maxDrawdownPct) { this.maxDrawdownPct = maxDrawdownPct; }

    public List<TradeLogDto> getTrades() { return trades; }
    public void setTrades(List<TradeLogDto> trades) { this.trades = trades; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
