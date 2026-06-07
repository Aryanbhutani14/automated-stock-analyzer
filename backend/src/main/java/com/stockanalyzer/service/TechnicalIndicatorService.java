package com.stockanalyzer.service;

import com.stockanalyzer.entity.Stock;
import com.stockanalyzer.entity.StockPrice;
import com.stockanalyzer.entity.TechnicalIndicator;
import com.stockanalyzer.repository.StockPriceRepository;
import com.stockanalyzer.repository.StockRepository;
import com.stockanalyzer.repository.TechnicalIndicatorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.MathContext;
import java.math.RoundingMode;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Calculates and persists technical indicators for all active stocks.
 *
 * Indicators calculated:
 *  - MA-50   : 50-day Simple Moving Average
 *  - MA-220  : 220-day Simple Moving Average
 *  - RSI-14  : 14-period Relative Strength Index (Wilder's smoothing)
 *  - VolAvg20: 20-day average volume
 *  - 52w High/Low
 *  - Momentum: 12-month price return %
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class TechnicalIndicatorService {

    private static final int MA_SHORT       = 50;
    private static final int MA_LONG        = 220;
    private static final int RSI_PERIOD     = 14;
    private static final int VOL_PERIOD     = 20;
    private static final int WEEK_52_DAYS   = 252;
    private static final int MOMENTUM_DAYS  = 252; // ~12 months

    private static final MathContext MC = new MathContext(10, RoundingMode.HALF_UP);

    private final StockRepository stockRepository;
    private final StockPriceRepository stockPriceRepository;
    private final TechnicalIndicatorRepository indicatorRepository;

    // ─── Public API ───────────────────────────────────────────────────────────

    /**
     * Recalculate indicators for every active stock using the latest available prices.
     */
    @Transactional
    public void calculateForAllStocks() {
        List<Stock> activeStocks = stockRepository.findByActiveTrue();
        log.info("Calculating indicators for {} stocks", activeStocks.size());

        int ok = 0, skipped = 0;
        for (Stock stock : activeStocks) {
            try {
                boolean saved = calculateAndStore(stock);
                if (saved) ok++; else skipped++;
            } catch (Exception e) {
                log.error("Indicator calculation failed for {}: {}", stock.getSymbol(), e.getMessage());
            }
        }
        log.info("Indicator calculation done — saved={}, skipped={}", ok, skipped);
    }

    /**
     * Calculate indicators for a single stock and persist them.
     *
     * @return true if new indicator row was created
     */
    @Transactional
    public boolean calculateAndStore(Stock stock) {
        // Get the most recent price date for this stock
        Optional<StockPrice> latestOpt = stockPriceRepository.findLatestByStockId(stock.getId());
        if (latestOpt.isEmpty()) {
            log.debug("No price data for {} — skipping indicators", stock.getSymbol());
            return false;
        }

        LocalDate latestDate = latestOpt.get().getTradeDate();

        // Skip if already calculated for this date
        if (indicatorRepository.existsByStock_IdAndTradeDate(stock.getId(), latestDate)) {
            log.debug("Indicators already exist for {} on {}", stock.getSymbol(), latestDate);
            return false;
        }

        // Fetch enough history for the longest window
        List<StockPrice> prices = stockPriceRepository
                .findLatestNByStockId(stock.getId(), MOMENTUM_DAYS + 1);

        if (prices.size() < MA_SHORT) {
            log.debug("Insufficient data for {} ({} rows) — need at least {}", 
                      stock.getSymbol(), prices.size(), MA_SHORT);
            return false;
        }

        // prices are DESC (latest first) — extract close prices in same order
        List<BigDecimal> closes = prices.stream()
                .map(StockPrice::getClosePrice)
                .toList();

        List<Long> volumes = prices.stream()
                .map(StockPrice::getVolume)
                .toList();

        TechnicalIndicator indicator = TechnicalIndicator.builder()
                .stock(stock)
                .tradeDate(latestDate)
                .ma50(sma(closes, MA_SHORT))
                .ma220(prices.size() >= MA_LONG ? sma(closes, MA_LONG) : null)
                .rsi14(rsi(closes, RSI_PERIOD))
                .volumeAvg20(avgVolume(volumes, VOL_PERIOD))
                .week52High(rollingHigh(closes, Math.min(prices.size(), WEEK_52_DAYS)))
                .week52Low(rollingLow(closes, Math.min(prices.size(), WEEK_52_DAYS)))
                .momentumScore(momentum(closes, Math.min(prices.size() - 1, MOMENTUM_DAYS)))
                .build();

        indicatorRepository.save(indicator);
        log.debug("Saved indicators for {} on {}", stock.getSymbol(), latestDate);
        return true;
    }

    // ─── Calculation helpers ──────────────────────────────────────────────────

    /**
     * Simple Moving Average of the first {@code period} elements (DESC order → most recent).
     */
    private BigDecimal sma(List<BigDecimal> closes, int period) {
        if (closes.size() < period) return null;
        BigDecimal sum = BigDecimal.ZERO;
        for (int i = 0; i < period; i++) sum = sum.add(closes.get(i));
        return sum.divide(BigDecimal.valueOf(period), 4, RoundingMode.HALF_UP);
    }

    /**
     * RSI using Wilder's smoothed method.
     * Requires at least period+1 data points.
     */
    private BigDecimal rsi(List<BigDecimal> closes, int period) {
        if (closes.size() < period + 1) return null;

        // Build a chronological list for RSI (oldest first)
        List<BigDecimal> chrono = new ArrayList<>(closes.subList(0, period + 1));
        java.util.Collections.reverse(chrono);

        BigDecimal avgGain = BigDecimal.ZERO;
        BigDecimal avgLoss = BigDecimal.ZERO;

        // Initial averages over first 'period' changes
        for (int i = 1; i <= period; i++) {
            BigDecimal change = chrono.get(i).subtract(chrono.get(i - 1));
            if (change.compareTo(BigDecimal.ZERO) > 0) {
                avgGain = avgGain.add(change);
            } else {
                avgLoss = avgLoss.add(change.abs());
            }
        }
        avgGain = avgGain.divide(BigDecimal.valueOf(period), 10, RoundingMode.HALF_UP);
        avgLoss = avgLoss.divide(BigDecimal.valueOf(period), 10, RoundingMode.HALF_UP);

        if (avgLoss.compareTo(BigDecimal.ZERO) == 0) return BigDecimal.valueOf(100);

        BigDecimal rs = avgGain.divide(avgLoss, 10, RoundingMode.HALF_UP);
        BigDecimal rsi = BigDecimal.valueOf(100)
                .subtract(BigDecimal.valueOf(100)
                        .divide(BigDecimal.ONE.add(rs), 4, RoundingMode.HALF_UP));
        return rsi;
    }

    /** Average volume over the first {@code period} entries (most recent). */
    private Long avgVolume(List<Long> volumes, int period) {
        if (volumes.size() < period) return null;
        long sum = 0;
        int count = 0;
        for (int i = 0; i < period; i++) {
            if (volumes.get(i) != null) { sum += volumes.get(i); count++; }
        }
        return count == 0 ? null : sum / count;
    }

    /** Rolling high over the first {@code window} closes (most recent). */
    private BigDecimal rollingHigh(List<BigDecimal> closes, int window) {
        return closes.stream()
                .limit(window)
                .max(BigDecimal::compareTo)
                .orElse(null);
    }

    /** Rolling low over the first {@code window} closes (most recent). */
    private BigDecimal rollingLow(List<BigDecimal> closes, int window) {
        return closes.stream()
                .limit(window)
                .min(BigDecimal::compareTo)
                .orElse(null);
    }

    /**
     * Momentum = ((currentPrice - priceNDaysAgo) / priceNDaysAgo) * 100
     * Positive = bullish momentum, negative = bearish.
     */
    private BigDecimal momentum(List<BigDecimal> closes, int lookback) {
        if (closes.size() <= lookback || lookback <= 0) return null;
        BigDecimal current  = closes.get(0);
        BigDecimal past     = closes.get(lookback);
        if (past.compareTo(BigDecimal.ZERO) == 0) return null;
        return current.subtract(past)
                .divide(past, MC)
                .multiply(BigDecimal.valueOf(100))
                .setScale(4, RoundingMode.HALF_UP);
    }
}
