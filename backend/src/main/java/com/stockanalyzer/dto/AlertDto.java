package com.stockanalyzer.dto;

import com.stockanalyzer.entity.Alert;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@Builder
public class AlertDto {

    private Long   id;
    private String symbol;
    private String stockName;
    private String alertType;
    private BigDecimal threshold;
    private boolean active;
    private LocalDateTime lastTriggered;
    private LocalDateTime createdAt;

    public static AlertDto from(Alert a) {
        return AlertDto.builder()
                .id(a.getId())
                .symbol(a.getStock().getSymbol())
                .stockName(a.getStock().getName())
                .alertType(a.getAlertType().name())
                .threshold(a.getThreshold())
                .active(a.isActive())
                .lastTriggered(a.getLastTriggered())
                .createdAt(a.getCreatedAt())
                .build();
    }
}
