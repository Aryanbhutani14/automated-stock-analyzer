package com.stockanalyzer.dto;

import com.stockanalyzer.entity.Stock;
import com.stockanalyzer.entity.StockPrice;
import com.stockanalyzer.entity.TechnicalIndicator;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
public class StockDetailDto {

    private Long   id;
    private String symbol;
    private String name;
    private String exchange;
    private String sector;
    private String industry;

    // Latest price snapshot
    private LocalDate  tradeDate;
    private BigDecimal closePrice;
    private BigDecimal openPrice;
    private BigDecimal highPrice;
    private BigDecimal lowPrice;
    private Long       volume;

    // Latest indicators
    private BigDecimal ma50;
    private BigDecimal ma220;
    private BigDecimal rsi14;
    private Long       volumeAvg20;
    private BigDecimal week52High;
    private BigDecimal week52Low;
    private BigDecimal momentumScore;

    public static StockDetailDto from(Stock s, StockPrice p, TechnicalIndicator ind) {
        var builder = StockDetailDto.builder()
                .id(s.getId())
                .symbol(s.getSymbol())
                .name(s.getName())
                .exchange(s.getExchange())
                .sector(s.getSector())
                .industry(s.getIndustry());

        if (p != null) {
            builder.tradeDate(p.getTradeDate())
                   .closePrice(p.getClosePrice())
                   .openPrice(p.getOpenPrice())
                   .highPrice(p.getHighPrice())
                   .lowPrice(p.getLowPrice())
                   .volume(p.getVolume());
        }
        if (ind != null) {
            builder.ma50(ind.getMa50())
                   .ma220(ind.getMa220())
                   .rsi14(ind.getRsi14())
                   .volumeAvg20(ind.getVolumeAvg20())
                   .week52High(ind.getWeek52High())
                   .week52Low(ind.getWeek52Low())
                   .momentumScore(ind.getMomentumScore());
        }
        return builder.build();
    }
}
