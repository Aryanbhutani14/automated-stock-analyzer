package com.stockanalyzer.dto;

import com.stockanalyzer.entity.StockPrice;
import lombok.Builder;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDate;

@Data
@Builder
public class StockPriceDto {

    private LocalDate  tradeDate;
    private BigDecimal openPrice;
    private BigDecimal highPrice;
    private BigDecimal lowPrice;
    private BigDecimal closePrice;
    private BigDecimal adjClose;
    private Long       volume;

    public static StockPriceDto from(StockPrice p) {
        return StockPriceDto.builder()
                .tradeDate(p.getTradeDate())
                .openPrice(p.getOpenPrice())
                .highPrice(p.getHighPrice())
                .lowPrice(p.getLowPrice())
                .closePrice(p.getClosePrice())
                .adjClose(p.getAdjClose())
                .volume(p.getVolume())
                .build();
    }
}
