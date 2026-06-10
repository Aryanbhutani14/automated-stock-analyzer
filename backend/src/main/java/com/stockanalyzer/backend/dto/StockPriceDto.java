package com.stockanalyzer.backend.dto;

import com.stockanalyzer.backend.model.StockPrice;
import java.time.LocalDate;

public class StockPriceDto {
    private LocalDate date;
    private Double open;
    private Double high;
    private Double low;
    private Double close;
    private Long volume;

    public StockPriceDto() {}

    public StockPriceDto(LocalDate date, Double open, Double high, Double low, Double close, Long volume) {
        this.date = date;
        this.open = open;
        this.high = high;
        this.low = low;
        this.close = close;
        this.volume = volume;
    }

    public static StockPriceDto from(StockPrice sp) {
        return new StockPriceDto(
                sp.getTradeDate(),
                sp.getOpenPrice(),
                sp.getHighPrice(),
                sp.getLowPrice(),
                sp.getClosePrice(),
                sp.getVolume()
        );
    }

    // Getters and Setters
    public LocalDate getDate() { return date; }
    public void setDate(LocalDate date) { this.date = date; }

    public Double getOpen() { return open; }
    public void setOpen(Double open) { this.open = open; }

    public Double getHigh() { return high; }
    public void setHigh(Double high) { this.high = high; }

    public Double getLow() { return low; }
    public void setLow(Double low) { this.low = low; }

    public Double getClose() { return close; }
    public void setClose(Double close) { this.close = close; }

    public Long getVolume() { return volume; }
    public void setVolume(Long volume) { this.volume = volume; }
}
