package com.stockanalyzer.backend.model;

import jakarta.persistence.*;
import java.time.LocalDate;
import java.time.LocalDateTime;

@Entity
@Table(
    name = "technical_indicators",
    uniqueConstraints = {
        @UniqueConstraint(columnNames = {"stock_id", "trade_date"})
    }
)
public class TechnicalIndicator {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "stock_id", nullable = false)
    private Stock stock;

    @Column(name = "trade_date", nullable = false)
    private LocalDate tradeDate;

    @Column(name = "ma_50")
    private Double ma50;

    @Column(name = "ma_220")
    private Double ma220;

    @Column(name = "rsi_14")
    private Double rsi14;

    @Column(name = "volume_avg_20")
    private Long volumeAvg20;

    @Column(name = "week_52_high")
    private Double week52High;

    @Column(name = "week_52_low")
    private Double week52Low;

    @Column(name = "momentum_score")
    private Double momentumScore;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt = LocalDateTime.now();

    public TechnicalIndicator() {}

    public TechnicalIndicator(Stock stock, LocalDate tradeDate, Double ma50, Double ma220, Double rsi14, Long volumeAvg20, Double week52High, Double week52Low, Double momentumScore) {
        this.stock = stock;
        this.tradeDate = tradeDate;
        this.ma50 = ma50;
        this.ma220 = ma220;
        this.rsi14 = rsi14;
        this.volumeAvg20 = volumeAvg20;
        this.week52High = week52High;
        this.week52Low = week52Low;
        this.momentumScore = momentumScore;
    }

    // Getters and Setters
    public Long getId() { return id; }
    public void setId(Long id) { this.id = id; }

    public Stock getStock() { return stock; }
    public void setStock(Stock stock) { this.stock = stock; }

    public LocalDate getTradeDate() { return tradeDate; }
    public void setTradeDate(LocalDate tradeDate) { this.tradeDate = tradeDate; }

    public Double getMa50() { return ma50; }
    public void setMa50(Double ma50) { this.ma50 = ma50; }

    public Double getMa220() { return ma220; }
    public void setMa220(Double ma220) { this.ma220 = ma220; }

    public Double getRsi14() { return rsi14; }
    public void setRsi14(Double rsi14) { this.rsi14 = rsi14; }

    public Long getVolumeAvg20() { return volumeAvg20; }
    public void setVolumeAvg20(Long volumeAvg20) { this.volumeAvg20 = volumeAvg20; }

    public Double getWeek52High() { return week52High; }
    public void setWeek52High(Double week52High) { this.week52High = week52High; }

    public Double getWeek52Low() { return week52Low; }
    public void setWeek52Low(Double week52Low) { this.week52Low = week52Low; }

    public Double getMomentumScore() { return momentumScore; }
    public void setMomentumScore(Double momentumScore) { this.momentumScore = momentumScore; }

    public LocalDateTime getCreatedAt() { return createdAt; }
    public void setCreatedAt(LocalDateTime createdAt) { this.createdAt = createdAt; }
}
