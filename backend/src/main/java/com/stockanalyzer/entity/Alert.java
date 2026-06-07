package com.stockanalyzer.entity;

import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "alerts")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Alert {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    @ManyToOne(fetch = FetchType.LAZY, optional = false)
    @JoinColumn(name = "stock_id", nullable = false)
    private Stock stock;

    @Enumerated(EnumType.STRING)
    @Column(name = "alert_type", nullable = false, length = 30)
    private AlertType alertType;

    @Column(name = "threshold", precision = 12, scale = 4)
    private BigDecimal threshold;

    @Column(name = "is_active", nullable = false)
    @Builder.Default
    private boolean active = true;

    @Column(name = "last_triggered")
    private LocalDateTime lastTriggered;

    @Column(name = "created_at", nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        createdAt = LocalDateTime.now();
    }

    public enum AlertType {
        PRICE_ABOVE,
        PRICE_BELOW,
        MA50_CROSSOVER_UP,
        MA50_CROSSOVER_DOWN,
        MA220_CROSSOVER_UP,
        MA220_CROSSOVER_DOWN,
        RSI_OVERBOUGHT,
        RSI_OVERSOLD,
        VOLUME_BREAKOUT,
        WEEK_52_HIGH
    }
}
