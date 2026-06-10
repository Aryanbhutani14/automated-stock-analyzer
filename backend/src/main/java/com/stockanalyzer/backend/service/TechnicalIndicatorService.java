package com.stockanalyzer.backend.service;

import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import com.stockanalyzer.backend.model.TechnicalIndicator;
import com.stockanalyzer.backend.repository.StockPriceRepository;
import com.stockanalyzer.backend.repository.StockRepository;
import com.stockanalyzer.backend.repository.TechnicalIndicatorRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Service
public class TechnicalIndicatorService {

    private static final Logger logger = LoggerFactory.getLogger(TechnicalIndicatorService.class);

    private static final int MA_SHORT       = 50;
    private static final int MA_LONG        = 220;
    private static final int RSI_PERIOD     = 14;
    private static final int VOL_PERIOD     = 20;
    private static final int WEEK_52_DAYS   = 252;
    private static final int MOMENTUM_DAYS  = 252; // ~12 months of trading days

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private StockPriceRepository stockPriceRepository;

    @Autowired
    private TechnicalIndicatorRepository indicatorRepository;

    @Transactional
    public void calculateForAllStocks() {
        List<Stock> activeStocks = stockRepository.findByIsActiveTrue();
        logger.info("Calculating technical indicators for {} active stocks...", activeStocks.size());

        int calculated = 0;
        int skipped = 0;

        for (Stock stock : activeStocks) {
            try {
                boolean saved = calculateAndStore(stock);
                if (saved) {
                    calculated++;
                } else {
                    skipped++;
                }
            } catch (Exception e) {
                logger.error("Indicator calculation failed for {}: {}", stock.getSymbol(), e.getMessage());
            }
        }
        logger.info("Indicator calculation finished: {} calculated, {} skipped.", calculated, skipped);
    }

    @Transactional
    public boolean calculateAndStore(Stock stock) {
        Optional<StockPrice> latestOpt = stockPriceRepository.findLatestByStockId(stock.getId());
        if (latestOpt.isEmpty()) {
            logger.debug("No price data for {} - skipping indicators", stock.getSymbol());
            return false;
        }

        LocalDate latestDate = latestOpt.get().getTradeDate();

        // Check if indicators already calculated for this date
        if (indicatorRepository.existsByStock_IdAndTradeDate(stock.getId(), latestDate)) {
            logger.debug("Indicators already exist for {} on {}", stock.getSymbol(), latestDate);
            return false;
        }

        // Fetch enough history for the longest window
        List<StockPrice> prices = stockPriceRepository.findLatestNByStockId(stock.getId(), MOMENTUM_DAYS + 1);

        if (prices.size() < MA_SHORT) {
            logger.debug("Insufficient data for {} ({} rows) - need at least {}", 
                    stock.getSymbol(), prices.size(), MA_SHORT);
            return false;
        }

        List<Double> closes = prices.stream()
                .map(StockPrice::getClosePrice)
                .toList();

        List<Long> volumes = prices.stream()
                .map(StockPrice::getVolume)
                .toList();

        Double ma50Val = sma(closes, MA_SHORT);
        Double ma220Val = prices.size() >= MA_LONG ? sma(closes, MA_LONG) : null;
        Double rsiVal = rsi(closes, RSI_PERIOD);
        Long volAvg20Val = avgVolume(volumes, VOL_PERIOD);
        Double week52HighVal = rollingHigh(closes, Math.min(prices.size(), WEEK_52_DAYS));
        Double week52LowVal = rollingLow(closes, Math.min(prices.size(), WEEK_52_DAYS));
        Double momentumVal = momentum(closes, Math.min(prices.size() - 1, MOMENTUM_DAYS));

        TechnicalIndicator indicator = new TechnicalIndicator(
                stock,
                latestDate,
                ma50Val,
                ma220Val,
                rsiVal,
                volAvg20Val,
                week52HighVal,
                week52LowVal,
                momentumVal
        );

        indicatorRepository.save(indicator);
        logger.debug("Saved indicators for {} on {}", stock.getSymbol(), latestDate);
        return true;
    }

    private Double sma(List<Double> closes, int period) {
        if (closes.size() < period) return null;
        double sum = 0.0;
        for (int i = 0; i < period; i++) {
            sum += closes.get(i);
        }
        double avg = sum / period;
        return Math.round(avg * 10000.0) / 10000.0;
    }

    private Double rsi(List<Double> closes, int period) {
        if (closes.size() < period + 1) return null;

        List<Double> fullChrono = new java.util.ArrayList<>(closes);
        java.util.Collections.reverse(fullChrono);

        double gain = 0.0;
        double loss = 0.0;

        // First simple average for RSI initialization
        for (int i = 1; i <= period; i++) {
            double change = fullChrono.get(i) - fullChrono.get(i - 1);
            if (change > 0) {
                gain += change;
            } else {
                loss += Math.abs(change);
            }
        }

        double smoothedGain = gain / period;
        double smoothedLoss = loss / period;

        // Wilder's smoothing for subsequent data points
        for (int i = period + 1; i < fullChrono.size(); i++) {
            double change = fullChrono.get(i) - fullChrono.get(i - 1);
            double currentGain = change > 0 ? change : 0.0;
            double currentLoss = change < 0 ? Math.abs(change) : 0.0;
            smoothedGain = (smoothedGain * (period - 1) + currentGain) / period;
            smoothedLoss = (smoothedLoss * (period - 1) + currentLoss) / period;
        }

        if (smoothedLoss == 0.0) return 100.0;

        double rs = smoothedGain / smoothedLoss;
        double rsiValue = 100.0 - (100.0 / (1.0 + rs));
        return Math.round(rsiValue * 10000.0) / 10000.0;
    }

    private Long avgVolume(List<Long> volumes, int period) {
        if (volumes.size() < period) return null;
        long sum = 0;
        int count = 0;
        for (int i = 0; i < period; i++) {
            if (volumes.get(i) != null) {
                sum += volumes.get(i);
                count++;
            }
        }
        return count == 0 ? null : sum / count;
    }

    private Double rollingHigh(List<Double> closes, int window) {
        if (closes.isEmpty()) return null;
        double max = closes.get(0);
        int limit = Math.min(closes.size(), window);
        for (int i = 1; i < limit; i++) {
            if (closes.get(i) > max) {
                max = closes.get(i);
            }
        }
        return max;
    }

    private Double rollingLow(List<Double> closes, int window) {
        if (closes.isEmpty()) return null;
        double min = closes.get(0);
        int limit = Math.min(closes.size(), window);
        for (int i = 1; i < limit; i++) {
            if (closes.get(i) < min) {
                min = closes.get(i);
            }
        }
        return min;
    }

    private Double momentum(List<Double> closes, int lookback) {
        if (closes.size() <= lookback || lookback <= 0) return null;
        double current = closes.get(0);
        double past = closes.get(lookback);
        if (past == 0.0) return null;
        double score = ((current - past) / past) * 100.0;
        return Math.round(score * 10000.0) / 10000.0;
    }
}
