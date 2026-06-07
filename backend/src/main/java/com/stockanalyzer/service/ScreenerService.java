package com.stockanalyzer.service;

import com.stockanalyzer.dto.ScreenerResultDto;
import com.stockanalyzer.entity.Stock;
import com.stockanalyzer.entity.TechnicalIndicator;
import com.stockanalyzer.repository.StockPriceRepository;
import com.stockanalyzer.repository.StockRepository;
import com.stockanalyzer.repository.TechnicalIndicatorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;

/**
 * Applies screener filters to all active stocks and returns matching results.
 *
 * Supported filters:
 *  MA220_CROSSOVER  — close > MA-220
 *  MA50_CROSSOVER   — close > MA-50
 *  WEEK_52_HIGH     — close within 2% of 52-week high
 *  VOLUME_BREAKOUT  — today's volume > 1.5× 20-day avg volume
 *  RSI_OVERSOLD     — RSI-14 < 35 (potential reversal)
 *  RSI_OVERBOUGHT   — RSI-14 > 70 (momentum continuation)
 *  MOMENTUM         — 12-month momentum score > 20%
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ScreenerService {

    private static final BigDecimal WEEK_52_HIGH_THRESHOLD = new BigDecimal("0.98"); // within 2%
    private static final BigDecimal VOLUME_MULTIPLIER      = new BigDecimal("1.5");
    private static final BigDecimal RSI_OVERSOLD           = new BigDecimal("35");
    private static final BigDecimal RSI_OVERBOUGHT         = new BigDecimal("70");
    private static final BigDecimal MOMENTUM_THRESHOLD     = new BigDecimal("20");

    private final StockRepository stockRepository;
    private final StockPriceRepository stockPriceRepository;
    private final TechnicalIndicatorRepository indicatorRepository;

    public enum ScreenerFilter {
        MA220_CROSSOVER,
        MA50_CROSSOVER,
        WEEK_52_HIGH,
        VOLUME_BREAKOUT,
        RSI_OVERSOLD,
        RSI_OVERBOUGHT,
        MOMENTUM,
        ALL
    }

    // ─── Public API ───────────────────────────────────────────────────────────

    /**
     * Run the screener for a specific filter (or ALL) across all active stocks.
     */
    @Transactional(readOnly = true)
    public List<ScreenerResultDto> screen(ScreenerFilter filter, String exchange, String sector) {
        List<Stock> stocks = getFilteredStockList(exchange, sector);
        List<ScreenerResultDto> results = new ArrayList<>();

        for (Stock stock : stocks) {
            var priceOpt     = stockPriceRepository.findLatestByStockId(stock.getId());
            var indicatorOpt = indicatorRepository.findLatestByStockId(stock.getId());

            if (priceOpt.isEmpty() || indicatorOpt.isEmpty()) continue;

            var price     = priceOpt.get();
            var indicator = indicatorOpt.get();
            BigDecimal close  = price.getClosePrice();
            Long       volume = price.getVolume();

            boolean matches = switch (filter) {
                case MA220_CROSSOVER  -> isAbove(close, indicator.getMa220());
                case MA50_CROSSOVER   -> isAbove(close, indicator.getMa50());
                case WEEK_52_HIGH     -> isNear52WeekHigh(close, indicator.getWeek52High());
                case VOLUME_BREAKOUT  -> isVolumeBreakout(volume, indicator.getVolumeAvg20());
                case RSI_OVERSOLD     -> isRsiOversold(indicator.getRsi14());
                case RSI_OVERBOUGHT   -> isRsiOverbought(indicator.getRsi14());
                case MOMENTUM         -> isStrongMomentum(indicator.getMomentumScore());
                case ALL              -> true;
            };

            if (matches) {
                results.add(ScreenerResultDto.from(stock, price, indicator, filter.name()));
            }
        }

        log.info("Screener [{}] — {} matches from {} stocks", filter, results.size(), stocks.size());
        return results;
    }

    /**
     * Run ALL filters and tag each stock with every matched filter it passes.
     */
    @Transactional(readOnly = true)
    public List<ScreenerResultDto> screenAll(String exchange, String sector) {
        List<Stock> stocks = getFilteredStockList(exchange, sector);
        List<ScreenerResultDto> results = new ArrayList<>();

        for (Stock stock : stocks) {
            var priceOpt     = stockPriceRepository.findLatestByStockId(stock.getId());
            var indicatorOpt = indicatorRepository.findLatestByStockId(stock.getId());

            if (priceOpt.isEmpty() || indicatorOpt.isEmpty()) continue;

            var price     = priceOpt.get();
            var indicator = indicatorOpt.get();
            BigDecimal close  = price.getClosePrice();
            Long       volume = price.getVolume();

            List<String> matched = new ArrayList<>();
            if (isAbove(close, indicator.getMa220()))                  matched.add("MA220_CROSSOVER");
            if (isAbove(close, indicator.getMa50()))                   matched.add("MA50_CROSSOVER");
            if (isNear52WeekHigh(close, indicator.getWeek52High()))    matched.add("WEEK_52_HIGH");
            if (isVolumeBreakout(volume, indicator.getVolumeAvg20()))  matched.add("VOLUME_BREAKOUT");
            if (isRsiOversold(indicator.getRsi14()))                   matched.add("RSI_OVERSOLD");
            if (isRsiOverbought(indicator.getRsi14()))                 matched.add("RSI_OVERBOUGHT");
            if (isStrongMomentum(indicator.getMomentumScore()))        matched.add("MOMENTUM");

            if (!matched.isEmpty()) {
                results.add(ScreenerResultDto.from(stock, price, indicator,
                        String.join(", ", matched)));
            }
        }
        return results;
    }

    // ─── Filter logic ─────────────────────────────────────────────────────────

    private boolean isAbove(BigDecimal close, BigDecimal ma) {
        return close != null && ma != null && close.compareTo(ma) > 0;
    }

    private boolean isNear52WeekHigh(BigDecimal close, BigDecimal high52w) {
        if (close == null || high52w == null || high52w.compareTo(BigDecimal.ZERO) == 0) return false;
        // close >= 98% of 52-week high
        return close.compareTo(high52w.multiply(WEEK_52_HIGH_THRESHOLD)) >= 0;
    }

    private boolean isVolumeBreakout(Long volume, Long avgVolume) {
        if (volume == null || avgVolume == null || avgVolume == 0) return false;
        return new BigDecimal(volume)
                .compareTo(new BigDecimal(avgVolume).multiply(VOLUME_MULTIPLIER)) >= 0;
    }

    private boolean isRsiOversold(BigDecimal rsi) {
        return rsi != null && rsi.compareTo(RSI_OVERSOLD) < 0;
    }

    private boolean isRsiOverbought(BigDecimal rsi) {
        return rsi != null && rsi.compareTo(RSI_OVERBOUGHT) > 0;
    }

    private boolean isStrongMomentum(BigDecimal momentum) {
        return momentum != null && momentum.compareTo(MOMENTUM_THRESHOLD) > 0;
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private List<Stock> getFilteredStockList(String exchange, String sector) {
        if (exchange != null && !exchange.isBlank()) {
            return stockRepository.findByExchangeAndActiveTrue(exchange.toUpperCase());
        }
        if (sector != null && !sector.isBlank()) {
            return stockRepository.findBySectorAndActiveTrue(sector);
        }
        return stockRepository.findByActiveTrue();
    }
}
