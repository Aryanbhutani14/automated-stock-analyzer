package com.stockanalyzer.backend.service;

import com.stockanalyzer.backend.dto.ScreenerResultDto;
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

import java.util.ArrayList;
import java.util.List;

@Service
public class ScreenerService {

    private static final Logger logger = LoggerFactory.getLogger(ScreenerService.class);

    private static final double WEEK_52_HIGH_THRESHOLD = 0.98; // within 2%
    private static final double VOLUME_MULTIPLIER      = 1.5;
    private static final double RSI_OVERSOLD           = 35.0;
    private static final double RSI_OVERBOUGHT         = 70.0;
    private static final double MOMENTUM_THRESHOLD     = 20.0;

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private StockPriceRepository stockPriceRepository;

    @Autowired
    private TechnicalIndicatorRepository indicatorRepository;

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

    @Transactional(readOnly = true)
    public List<ScreenerResultDto> screen(ScreenerFilter filter, String exchange, String sector) {
        List<Stock> stocks = getFilteredStockList(exchange, sector);
        List<ScreenerResultDto> results = new ArrayList<>();

        for (Stock stock : stocks) {
            var priceOpt = stockPriceRepository.findLatestByStockId(stock.getId());
            var indicatorOpt = indicatorRepository.findLatestByStockId(stock.getId());

            if (priceOpt.isEmpty() || indicatorOpt.isEmpty()) continue;

            StockPrice price = priceOpt.get();
            TechnicalIndicator indicator = indicatorOpt.get();
            Double close = price.getClosePrice();
            Long volume = price.getVolume();

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

        logger.info("Screener [{}] - {} matches from {} stocks", filter, results.size(), stocks.size());
        return results;
    }

    @Transactional(readOnly = true)
    public List<ScreenerResultDto> screenAll(String exchange, String sector) {
        List<Stock> stocks = getFilteredStockList(exchange, sector);
        List<ScreenerResultDto> results = new ArrayList<>();

        for (Stock stock : stocks) {
            var priceOpt = stockPriceRepository.findLatestByStockId(stock.getId());
            var indicatorOpt = indicatorRepository.findLatestByStockId(stock.getId());

            if (priceOpt.isEmpty() || indicatorOpt.isEmpty()) continue;

            StockPrice price = priceOpt.get();
            TechnicalIndicator indicator = indicatorOpt.get();
            Double close = price.getClosePrice();
            Long volume = price.getVolume();

            List<String> matched = new ArrayList<>();
            if (isAbove(close, indicator.getMa220()))                 matched.add("MA220_CROSSOVER");
            if (isAbove(close, indicator.getMa50()))                  matched.add("MA50_CROSSOVER");
            if (isNear52WeekHigh(close, indicator.getWeek52High()))   matched.add("WEEK_52_HIGH");
            if (isVolumeBreakout(volume, indicator.getVolumeAvg20())) matched.add("VOLUME_BREAKOUT");
            if (isRsiOversold(indicator.getRsi14()))                  matched.add("RSI_OVERSOLD");
            if (isRsiOverbought(indicator.getRsi14()))                matched.add("RSI_OVERBOUGHT");
            if (isStrongMomentum(indicator.getMomentumScore()))       matched.add("MOMENTUM");

            if (!matched.isEmpty()) {
                results.add(ScreenerResultDto.from(stock, price, indicator, String.join(", ", matched)));
            }
        }
        return results;
    }

    private boolean isAbove(Double close, Double ma) {
        return close != null && ma != null && close > ma;
    }

    private boolean isNear52WeekHigh(Double close, Double high52w) {
        if (close == null || high52w == null || high52w == 0.0) return false;
        return close >= high52w * WEEK_52_HIGH_THRESHOLD;
    }

    private boolean isVolumeBreakout(Long volume, Long avgVolume) {
        if (volume == null || avgVolume == null || avgVolume == 0) return false;
        return volume >= avgVolume * VOLUME_MULTIPLIER;
    }

    private boolean isRsiOversold(Double rsi) {
        return rsi != null && rsi < RSI_OVERSOLD;
    }

    private boolean isRsiOverbought(Double rsi) {
        return rsi != null && rsi > RSI_OVERBOUGHT;
    }

    private boolean isStrongMomentum(Double momentum) {
        return momentum != null && momentum > MOMENTUM_THRESHOLD;
    }

    private List<Stock> getFilteredStockList(String exchange, String sector) {
        if (exchange != null && !exchange.trim().isEmpty()) {
            return stockRepository.findByExchangeAndIsActiveTrue(exchange.toUpperCase());
        }
        if (sector != null && !sector.trim().isEmpty()) {
            return stockRepository.findBySectorAndIsActiveTrue(sector);
        }
        return stockRepository.findByIsActiveTrue();
    }
}
