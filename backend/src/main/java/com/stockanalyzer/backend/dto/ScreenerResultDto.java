package com.stockanalyzer.backend.dto;

import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import com.stockanalyzer.backend.model.TechnicalIndicator;
import java.time.LocalDate;

public class ScreenerResultDto {

    private String symbol;
    private String name;
    private String exchange;
    private String sector;

    // Price info
    private LocalDate tradeDate;
    private Double closePrice;
    private Double openPrice;
    private Double highPrice;
    private Double lowPrice;
    private Long volume;

    // Indicators
    private Double ma50;
    private Double ma220;
    private Double rsi14;
    private Long volumeAvg20;
    private Double week52High;
    private Double week52Low;
    private Double momentumScore;

    // Which filter(s) matched
    private String matchedFilters;

    public ScreenerResultDto() {}

    public ScreenerResultDto(String symbol, String name, String exchange, String sector, LocalDate tradeDate, Double closePrice, Double openPrice, Double highPrice, Double lowPrice, Long volume, Double ma50, Double ma220, Double rsi14, Long volumeAvg20, Double week52High, Double week52Low, Double momentumScore, String matchedFilters) {
        this.symbol = symbol;
        this.name = name;
        this.exchange = exchange;
        this.sector = sector;
        this.tradeDate = tradeDate;
        this.closePrice = closePrice;
        this.openPrice = openPrice;
        this.highPrice = highPrice;
        this.lowPrice = lowPrice;
        this.volume = volume;
        this.ma50 = ma50;
        this.ma220 = ma220;
        this.rsi14 = rsi14;
        this.volumeAvg20 = volumeAvg20;
        this.week52High = week52High;
        this.week52Low = week52Low;
        this.momentumScore = momentumScore;
        this.matchedFilters = matchedFilters;
    }

    public static ScreenerResultDto from(Stock stock, StockPrice price, TechnicalIndicator ind, String filters) {
        return new ScreenerResultDto(
                stock.getSymbol(),
                stock.getName(),
                stock.getExchange(),
                stock.getSector(),
                price != null ? price.getTradeDate() : null,
                price != null ? price.getClosePrice() : null,
                price != null ? price.getOpenPrice() : null,
                price != null ? price.getHighPrice() : null,
                price != null ? price.getLowPrice() : null,
                price != null ? price.getVolume() : null,
                ind != null ? ind.getMa50() : null,
                ind != null ? ind.getMa220() : null,
                ind != null ? ind.getRsi14() : null,
                ind != null ? ind.getVolumeAvg20() : null,
                ind != null ? ind.getWeek52High() : null,
                ind != null ? ind.getWeek52Low() : null,
                ind != null ? ind.getMomentumScore() : null,
                filters
        );
    }

    // Getters and Setters
    public String getSymbol() { return symbol; }
    public void setSymbol(String symbol) { this.symbol = symbol; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getExchange() { return exchange; }
    public void setExchange(String exchange) { this.exchange = exchange; }

    public String getSector() { return sector; }
    public void setSector(String sector) { this.sector = sector; }

    public LocalDate getTradeDate() { return tradeDate; }
    public void setTradeDate(LocalDate tradeDate) { this.tradeDate = tradeDate; }

    public Double getClosePrice() { return closePrice; }
    public void setClosePrice(Double closePrice) { this.closePrice = closePrice; }

    public Double getOpenPrice() { return openPrice; }
    public void setOpenPrice(Double openPrice) { this.openPrice = openPrice; }

    public Double getHighPrice() { return highPrice; }
    public void setHighPrice(Double highPrice) { this.highPrice = highPrice; }

    public Double getLowPrice() { return lowPrice; }
    public void setLowPrice(Double lowPrice) { this.lowPrice = lowPrice; }

    public Long getVolume() { return volume; }
    public void setVolume(Long volume) { this.volume = volume; }

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

    public String getMatchedFilters() { return matchedFilters; }
    public void setMatchedFilters(String matchedFilters) { this.matchedFilters = matchedFilters; }
}
