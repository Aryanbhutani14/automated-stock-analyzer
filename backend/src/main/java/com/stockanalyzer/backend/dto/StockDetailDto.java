package com.stockanalyzer.backend.dto;

import java.time.LocalDate;
import java.util.List;

public class StockDetailDto {
    private StockDto stock;
    private List<PricePoint> history;
    private Double ma50;
    private Double ma220;
    private Double rsi14;
    private Long volumeAvg20;
    private Double week52High;
    private Double week52Low;
    private Double momentumScore;

    public StockDetailDto() {}

    public StockDetailDto(StockDto stock, List<PricePoint> history) {
        this.stock = stock;
        this.history = history;
    }

    public StockDetailDto(StockDto stock, List<PricePoint> history, Double ma50, Double ma220, Double rsi14, Long volumeAvg20, Double week52High, Double week52Low, Double momentumScore) {
        this.stock = stock;
        this.history = history;
        this.ma50 = ma50;
        this.ma220 = ma220;
        this.rsi14 = rsi14;
        this.volumeAvg20 = volumeAvg20;
        this.week52High = week52High;
        this.week52Low = week52Low;
        this.momentumScore = momentumScore;
    }

    public StockDto getStock() { return stock; }
    public void setStock(StockDto stock) { this.stock = stock; }

    public List<PricePoint> getHistory() { return history; }
    public void setHistory(List<PricePoint> history) { this.history = history; }

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


    public static class PricePoint {
        private LocalDate date;
        private Double open;
        private Double high;
        private Double low;
        private Double close;
        private Long volume;

        public PricePoint() {}

        public PricePoint(LocalDate date, Double open, Double high, Double low, Double close, Long volume) {
            this.date = date;
            this.open = open;
            this.high = high;
            this.low = low;
            this.close = close;
            this.volume = volume;
        }

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
}
