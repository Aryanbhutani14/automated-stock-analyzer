package com.stockanalyzer.backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "backtest_results")
public class BacktestResult {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "strategy_name", nullable = false)
    private String strategyName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "stock_id")
    private Stock stock;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "total_return_pct")
    private Double totalReturnPct;

    @Column(name = "win_rate_pct")
    private Double winRatePct;

    @Column(name = "total_trades")
    private Integer totalTrades;

    @Column(name = "max_drawdown_pct")
    private Double maxDrawdownPct;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public BacktestResult() {}

    public BacktestResult(User user, String strategyName, Stock stock, LocalDate startDate, LocalDate endDate,
                          Double totalReturnPct, Double winRatePct, Integer totalTrades, Double maxDrawdownPct) {
        this.user = user;
        this.strategyName = strategyName;
        this.stock = stock;
        this.startDate = startDate;
        this.endDate = endDate;
        this.totalReturnPct = totalReturnPct;
        this.winRatePct = winRatePct;
        this.totalTrades = totalTrades;
        this.maxDrawdownPct = maxDrawdownPct;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public User getUser() { return user; }
    public void setUser(User user) { this.user = user; }

    public String getStrategyName() { return strategyName; }
    public void setStrategyName(String strategyName) { this.strategyName = strategyName; }

    public Stock getStock() { return stock; }
    public void setStock(Stock stock) { this.stock = stock; }

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

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
