package com.stockanalyzer.dto;

import com.stockanalyzer.entity.BacktestResult;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;

@Data
@Builder
public class BacktestResultDto {

    private String     symbol;
    private String     strategy;
    private LocalDate  startDate;
    private LocalDate  endDate;
    private BigDecimal totalReturnPct;
    private BigDecimal winRatePct;
    private Integer    totalTrades;
    private BigDecimal maxDrawdownPct;
    private List<TradeRecord> trades;
    private String     message;

    @Data
    @Builder
    public static class TradeRecord {
        private LocalDate  entryDate;
        private LocalDate  exitDate;
        private BigDecimal entryPrice;
        private BigDecimal exitPrice;
        private BigDecimal returnPct;
    }

    /** Convert persisted entity back to DTO (no trade-level detail in stored results) */
    public static BacktestResultDto fromEntity(BacktestResult r) {
        return BacktestResultDto.builder()
                .symbol(r.getStock() != null ? r.getStock().getSymbol() : "—")
                .strategy(r.getStrategyName())
                .startDate(r.getStartDate())
                .endDate(r.getEndDate())
                .totalReturnPct(r.getTotalReturnPct())
                .winRatePct(r.getWinRatePct())
                .totalTrades(r.getTotalTrades())
                .maxDrawdownPct(r.getMaxDrawdownPct())
                .build();
    }
}
