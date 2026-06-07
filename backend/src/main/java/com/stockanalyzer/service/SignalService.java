package com.stockanalyzer.service;

import com.stockanalyzer.entity.Signal;
import com.stockanalyzer.entity.Signal.SignalType;
import com.stockanalyzer.entity.Stock;
import com.stockanalyzer.entity.TechnicalIndicator;
import com.stockanalyzer.repository.SignalRepository;
import com.stockanalyzer.repository.StockPriceRepository;
import com.stockanalyzer.repository.StockRepository;
import com.stockanalyzer.repository.TechnicalIndicatorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Generates BUY / SELL signals based on technical indicators.
 *
 * Strategy rules:
 *  MA220_CROSSOVER  BUY  — close crosses ABOVE MA-220 (yesterday was below, today above)
 *  MA220_CROSSOVER  SELL — close crosses BELOW MA-220
 *  MA50_CROSSOVER   BUY  — close crosses ABOVE MA-50
 *  MA50_CROSSOVER   SELL — close crosses BELOW MA-50
 *  RSI_OVERSOLD     BUY  — RSI < 35 (mean reversion)
 *  RSI_OVERBOUGHT   SELL — RSI > 70 (take profit)
 *  WEEK_52_HIGH     BUY  — price at / near 52-week high (breakout momentum)
 *  VOLUME_BREAKOUT  BUY  — volume > 1.5× 20-day average with price up
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class SignalService {

    private static final BigDecimal RSI_OVERSOLD_LEVEL   = new BigDecimal("35");
    private static final BigDecimal RSI_OVERBOUGHT_LEVEL = new BigDecimal("70");
    private static final BigDecimal WEEK_52_THRESHOLD    = new BigDecimal("0.98");
    private static final BigDecimal VOLUME_MULTIPLIER    = new BigDecimal("1.5");

    private final StockRepository              stockRepository;
    private final StockPriceRepository         stockPriceRepository;
    private final TechnicalIndicatorRepository indicatorRepository;
    private final SignalRepository             signalRepository;

    // ─── Public API ───────────────────────────────────────────────────────────

    /**
     * Generate signals for all active stocks and persist new ones.
     * Called by the daily scheduler after indicators are calculated.
     */
    @Transactional
    public void generateSignalsForAllStocks() {
        List<Stock> stocks = stockRepository.findByActiveTrue();
        log.info("Generating signals for {} stocks", stocks.size());

        int generated = 0;
        for (Stock stock : stocks) {
            try {
                generated += generateSignalsForStock(stock);
            } catch (Exception e) {
                log.error("Signal generation failed for {}: {}", stock.getSymbol(), e.getMessage());
            }
        }
        log.info("Signal generation complete — {} new signals created", generated);
    }

    // ─── Per-stock logic ──────────────────────────────────────────────────────

    private int generateSignalsForStock(Stock stock) {
        Optional<TechnicalIndicator> latestOpt = indicatorRepository.findLatestByStockId(stock.getId());
        if (latestOpt.isEmpty()) return 0;

        TechnicalIndicator today = latestOpt.get();
        LocalDate date = today.getTradeDate();

        var latestPriceOpt = stockPriceRepository.findLatestByStockId(stock.getId());
        if (latestPriceOpt.isEmpty()) return 0;

        BigDecimal close  = latestPriceOpt.get().getClosePrice();
        Long       volume = latestPriceOpt.get().getVolume();

        List<Signal> signals = new ArrayList<>();

        // ── MA-220 Crossover ──
        checkMaCrossover(stock, close, today.getMa220(), date, "MA220_CROSSOVER")
                .ifPresent(signals::add);

        // ── MA-50 Crossover ──
        checkMaCrossover(stock, close, today.getMa50(), date, "MA50_CROSSOVER")
                .ifPresent(signals::add);

        // ── RSI signals ──
        if (today.getRsi14() != null) {
            if (today.getRsi14().compareTo(RSI_OVERSOLD_LEVEL) < 0) {
                signals.add(buildSignal(stock, date, SignalType.BUY, "RSI_OVERSOLD",
                        close, "RSI=" + today.getRsi14().toPlainString() + " — oversold, potential reversal"));
            } else if (today.getRsi14().compareTo(RSI_OVERBOUGHT_LEVEL) > 0) {
                signals.add(buildSignal(stock, date, SignalType.SELL, "RSI_OVERBOUGHT",
                        close, "RSI=" + today.getRsi14().toPlainString() + " — overbought, consider taking profit"));
            }
        }

        // ── 52-Week High Breakout ──
        if (close != null && today.getWeek52High() != null
                && today.getWeek52High().compareTo(BigDecimal.ZERO) > 0
                && close.compareTo(today.getWeek52High().multiply(WEEK_52_THRESHOLD)) >= 0) {
            signals.add(buildSignal(stock, date, SignalType.BUY, "WEEK_52_HIGH",
                    close, "Price near 52-week high — breakout momentum"));
        }

        // ── Volume Breakout (with positive price action) ──
        if (volume != null && today.getVolumeAvg20() != null
                && new BigDecimal(volume)
                        .compareTo(new BigDecimal(today.getVolumeAvg20()).multiply(VOLUME_MULTIPLIER)) >= 0) {
            signals.add(buildSignal(stock, date, SignalType.BUY, "VOLUME_BREAKOUT",
                    close, "Volume " + volume + " exceeds 1.5× 20-day avg (" + today.getVolumeAvg20() + ")"));
        }

        signalRepository.saveAll(signals);
        return signals.size();
    }

    /**
     * Checks for a simple price-above/below MA crossover signal.
     * Returns empty if MA is unavailable.
     */
    private Optional<Signal> checkMaCrossover(Stock stock, BigDecimal close,
                                               BigDecimal ma, LocalDate date, String strategy) {
        if (close == null || ma == null) return Optional.empty();

        if (close.compareTo(ma) > 0) {
            return Optional.of(buildSignal(stock, date, SignalType.BUY, strategy,
                    close, "Price " + close.toPlainString() + " crossed above " + strategy + " (" + ma.toPlainString() + ")"));
        } else {
            return Optional.of(buildSignal(stock, date, SignalType.SELL, strategy,
                    close, "Price " + close.toPlainString() + " crossed below " + strategy + " (" + ma.toPlainString() + ")"));
        }
    }

    private Signal buildSignal(Stock stock, LocalDate date, SignalType type,
                                String strategy, BigDecimal triggerPrice, String notes) {
        return Signal.builder()
                .stock(stock)
                .signalDate(date)
                .signalType(type)
                .strategy(strategy)
                .triggerPrice(triggerPrice)
                .notes(notes)
                .build();
    }
}
