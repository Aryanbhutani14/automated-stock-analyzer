package com.stockanalyzer.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(name = "backtest_results")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class BacktestResult {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @Column(name = "strategy_name", nullable = false, length = 100)
    private String strategyName;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "stock_id")
    private Stock stock;   // null = portfolio-wide backtest

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "total_return_pct", precision = 8, scale = 4)
    private BigDecimal totalReturnPct;

    @Column(name = "win_rate_pct", precision = 8, scale = 4)
    private BigDecimal winRatePct;

    @Column(name = "total_trades")
    private Integer totalTrades;

    @Column(name = "max_drawdown_pct", precision = 8, scale = 4)
    private BigDecimal maxDrawdownPct;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
