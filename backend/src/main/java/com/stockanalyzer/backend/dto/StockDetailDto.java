package com.stockanalyzer.backend.dto;

import java.time.LocalDate;
import java.util.List;

public class StockDetailDto {
    private StockDto stock;
    private List<PricePoint> history;

    public StockDetailDto() {}

    public StockDetailDto(StockDto stock, List<PricePoint> history) {
        this.stock = stock;
        this.history = history;
    }

    public StockDto getStock() { return stock; }
    public void setStock(StockDto stock) { this.stock = stock; }

    public List<PricePoint> getHistory() { return history; }
    public void setHistory(List<PricePoint> history) { this.history = history; }

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
