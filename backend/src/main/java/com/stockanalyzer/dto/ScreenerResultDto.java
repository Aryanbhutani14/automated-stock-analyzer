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
public class ScreenerResultDto {

    private String   symbol;
    private String   name;
    private String   exchange;
    private String   sector;

    // Price info
    private LocalDate  tradeDate;
    private BigDecimal closePrice;
    private BigDecimal openPrice;
    private BigDecimal highPrice;
    private BigDecimal lowPrice;
    private Long       volume;

    // Indicators
    private BigDecimal ma50;
    private BigDecimal ma220;
    private BigDecimal rsi14;
    private Long       volumeAvg20;
    private BigDecimal week52High;
    private BigDecimal week52Low;
    private BigDecimal momentumScore;

    // Which filter(s) matched
    private String matchedFilters;

    public static ScreenerResultDto from(Stock stock, StockPrice price,
                                         TechnicalIndicator ind, String filters) {
        return ScreenerResultDto.builder()
                .symbol(stock.getSymbol())
                .name(stock.getName())
                .exchange(stock.getExchange())
                .sector(stock.getSector())
                .tradeDate(price.getTradeDate())
                .closePrice(price.getClosePrice())
                .openPrice(price.getOpenPrice())
                .highPrice(price.getHighPrice())
                .lowPrice(price.getLowPrice())
                .volume(price.getVolume())
                .ma50(ind.getMa50())
                .ma220(ind.getMa220())
                .rsi14(ind.getRsi14())
                .volumeAvg20(ind.getVolumeAvg20())
                .week52High(ind.getWeek52High())
                .week52Low(ind.getWeek52Low())
                .momentumScore(ind.getMomentumScore())
                .matchedFilters(filters)
                .build();
    }
}
