package com.stockanalyzer.backend.service;

import com.stockanalyzer.backend.model.Signal;
import com.stockanalyzer.backend.model.Signal.SignalType;
import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import com.stockanalyzer.backend.model.TechnicalIndicator;
import com.stockanalyzer.backend.repository.SignalRepository;
import com.stockanalyzer.backend.repository.StockPriceRepository;
import com.stockanalyzer.backend.repository.StockRepository;
import com.stockanalyzer.backend.repository.TechnicalIndicatorRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class SignalService {

    private static final Logger logger = LoggerFactory.getLogger(SignalService.class);

    private static final double RSI_OVERSOLD_LEVEL   = 35.0;
    private static final double RSI_OVERBOUGHT_LEVEL = 70.0;
    private static final double WEEK_52_THRESHOLD    = 0.98;
    private static final double VOLUME_MULTIPLIER    = 1.5;

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private StockPriceRepository stockPriceRepository;

    @Autowired
    private TechnicalIndicatorRepository indicatorRepository;

    @Autowired
    private SignalRepository signalRepository;

    @Transactional
    public void generateSignalsForAllStocks() {
        List<Stock> stocks = stockRepository.findByIsActiveTrue();
        logger.info("Generating signals for {} active stocks...", stocks.size());

        int generated = 0;
        for (Stock stock : stocks) {
            try {
                generated += generateSignalsForStock(stock);
            } catch (Exception e) {
                logger.error("Signal generation failed for {}: {}", stock.getSymbol(), e.getMessage());
            }
        }
        logger.info("Signal generation complete - {} new signals created.", generated);
    }

    private int generateSignalsForStock(Stock stock) {
        List<TechnicalIndicator> indicators = indicatorRepository.findTop2ByStockIdOrderByTradeDateDesc(stock.getId());
        if (indicators.isEmpty()) return 0;

        TechnicalIndicator todayIndicator = indicators.get(0);
        LocalDate todayDate = todayIndicator.getTradeDate();

        // Check if signals were already generated for this date
        // Since we check all strategies, we can check if signals exist for todayDate
        // (Typically we run the pipeline once per day, so check if any signal for this stock and date exists)
        // If they already exist, we skip to avoid duplicating signal cards
        boolean signalsExist = signalRepository.findByStock_SymbolIgnoreCaseOrderBySignalDateDesc(stock.getSymbol()).stream()
                .anyMatch(s -> s.getSignalDate().equals(todayDate));
        if (signalsExist) {
            logger.debug("Signals already exist for {} on {}", stock.getSymbol(), todayDate);
            return 0;
        }

        List<StockPrice> latestPrices = stockPriceRepository.findLatestNByStockId(stock.getId(), 2);
        if (latestPrices.isEmpty()) return 0;

        StockPrice todayPrice = latestPrices.get(0);
        Double todayClose = todayPrice.getClosePrice();
        Double todayOpen = todayPrice.getOpenPrice();
        Long todayVolume = todayPrice.getVolume();

        Double prevClose = latestPrices.size() >= 2 ? latestPrices.get(1).getClosePrice() : null;
        
        TechnicalIndicator prevIndicator = indicators.size() >= 2 ? indicators.get(1) : null;
        Double prevMa50 = prevIndicator != null ? prevIndicator.getMa50() : null;
        Double prevMa220 = prevIndicator != null ? prevIndicator.getMa220() : null;

        List<Signal> signals = new ArrayList<>();

        // 1. MA-220 Crossover
        checkMaCrossover(stock, todayClose, todayIndicator.getMa220(), prevClose, prevMa220, todayDate, "MA220_CROSSOVER")
                .ifPresent(signals::add);

        // 2. MA-50 Crossover
        checkMaCrossover(stock, todayClose, todayIndicator.getMa50(), prevClose, prevMa50, todayDate, "MA50_CROSSOVER")
                .ifPresent(signals::add);

        // 3. RSI signals
        if (todayIndicator.getRsi14() != null) {
            if (todayIndicator.getRsi14() < RSI_OVERSOLD_LEVEL) {
                signals.add(buildSignal(stock, todayDate, SignalType.BUY, "RSI_OVERSOLD", todayClose,
                        "RSI is " + todayIndicator.getRsi14() + " - oversold condition, potential reversal"));
            } else if (todayIndicator.getRsi14() > RSI_OVERBOUGHT_LEVEL) {
                signals.add(buildSignal(stock, todayDate, SignalType.SELL, "RSI_OVERBOUGHT", todayClose,
                        "RSI is " + todayIndicator.getRsi14() + " - overbought condition, consider taking profit"));
            }
        }

        // 4. 52-Week High Breakout
        if (todayClose != null && todayIndicator.getWeek52High() != null && todayIndicator.getWeek52High() > 0) {
            if (todayClose >= todayIndicator.getWeek52High() * WEEK_52_THRESHOLD) {
                signals.add(buildSignal(stock, todayDate, SignalType.BUY, "WEEK_52_HIGH", todayClose,
                        "Price is near 52-week high of ₹" + todayIndicator.getWeek52High() + " - breakout momentum"));
            }
        }

        // 5. Volume Breakout
        if (todayVolume != null && todayIndicator.getVolumeAvg20() != null && todayIndicator.getVolumeAvg20() > 0) {
            if (todayVolume >= todayIndicator.getVolumeAvg20() * VOLUME_MULTIPLIER && (todayOpen == null || todayClose > todayOpen)) {
                signals.add(buildSignal(stock, todayDate, SignalType.BUY, "VOLUME_BREAKOUT", todayClose,
                        "Volume (" + todayVolume + ") exceeds 1.5x of 20-day average (" + todayIndicator.getVolumeAvg20() + ") with positive price return"));
            }
        }

        if (!signals.isEmpty()) {
            signalRepository.saveAll(signals);
        }
        return signals.size();
    }

    private Optional<Signal> checkMaCrossover(Stock stock, Double close, Double ma, Double prevClose, Double prevMa, LocalDate date, String strategy) {
        if (close == null || ma == null) return Optional.empty();

        if (prevClose != null && prevMa != null) {
            boolean todayAbove = close > ma;
            boolean yesterdayAbove = prevClose > prevMa;

            if (todayAbove && !yesterdayAbove) {
                return Optional.of(buildSignal(stock, date, SignalType.BUY, strategy, close,
                        "Price crossed ABOVE " + (strategy.equals("MA50_CROSSOVER") ? "50-day MA" : "220-day MA") + " (₹" + Math.round(ma * 100.0) / 100.0 + ")"));
            } else if (!todayAbove && yesterdayAbove) {
                return Optional.of(buildSignal(stock, date, SignalType.SELL, strategy, close,
                        "Price crossed BELOW " + (strategy.equals("MA50_CROSSOVER") ? "50-day MA" : "220-day MA") + " (₹" + Math.round(ma * 100.0) / 100.0 + ")"));
            }
        } else {
            // Fallback: simple state check if yesterday's data is not available
            boolean todayAbove = close > ma;
            if (todayAbove) {
                return Optional.of(buildSignal(stock, date, SignalType.BUY, strategy, close,
                        "Price is above " + (strategy.equals("MA50_CROSSOVER") ? "50-day MA" : "220-day MA") + " (₹" + Math.round(ma * 100.0) / 100.0 + ")"));
            } else {
                return Optional.of(buildSignal(stock, date, SignalType.SELL, strategy, close,
                        "Price is below " + (strategy.equals("MA50_CROSSOVER") ? "50-day MA" : "220-day MA") + " (₹" + Math.round(ma * 100.0) / 100.0 + ")"));
            }
        }

        return Optional.empty();
    }

    private Signal buildSignal(Stock stock, LocalDate date, SignalType type, String strategy, Double triggerPrice, String notes) {
        return new Signal(stock, date, type, strategy, triggerPrice, notes);
    }
}
