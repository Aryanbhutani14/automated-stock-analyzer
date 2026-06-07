package com.stockanalyzer.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "technical_indicators",
    uniqueConstraints = @UniqueConstraint(columnNames = {"stock_id", "trade_date"})
)
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class TechnicalIndicator {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "stock_id", nullable = false)
    private Stock stock;

    @Column(name = "trade_date", nullable = false)
    private LocalDate tradeDate;

    @Column(name = "ma_50", precision = 12, scale = 4)
    private BigDecimal ma50;

    @Column(name = "ma_220", precision = 12, scale = 4)
    private BigDecimal ma220;

    @Column(name = "rsi_14", precision = 8, scale = 4)
    private BigDecimal rsi14;

    @Column(name = "volume_avg_20")
    private Long volumeAvg20;

    @Column(name = "week_52_high", precision = 12, scale = 4)
    private BigDecimal week52High;

    @Column(name = "week_52_low", precision = 12, scale = 4)
    private BigDecimal week52Low;

    @Column(name = "momentum_score", precision = 8, scale = 4)
    private BigDecimal momentumScore;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }
}
