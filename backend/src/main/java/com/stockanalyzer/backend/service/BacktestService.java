package com.stockanalyzer.backend.service;

import com.stockanalyzer.backend.dto.BacktestRequest;
import com.stockanalyzer.backend.dto.BacktestResultDto;
import com.stockanalyzer.backend.dto.TradeLogDto;
import com.stockanalyzer.backend.model.BacktestResult;
import com.stockanalyzer.backend.model.Signal;
import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import com.stockanalyzer.backend.model.User;
import com.stockanalyzer.backend.repository.BacktestResultRepository;
import com.stockanalyzer.backend.repository.SignalRepository;
import com.stockanalyzer.backend.repository.StockPriceRepository;
import com.stockanalyzer.backend.repository.StockRepository;
import com.stockanalyzer.backend.repository.UserRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class BacktestService {

    private static final Logger logger = LoggerFactory.getLogger(BacktestService.class);

    @Autowired
    private BacktestResultRepository backtestResultRepository;

    @Autowired
    private SignalRepository signalRepository;

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private StockPriceRepository stockPriceRepository;

    @Autowired
    private UserRepository userRepository;

    public BacktestResultDto runBacktest(String username, BacktestRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));

        Stock stock = stockRepository.findBySymbolIgnoreCase(request.getSymbol())
                .orElseThrow(() -> new IllegalArgumentException("Stock not found with symbol: " + request.getSymbol()));

        logger.info("Running backtest for user {}, stock {}, strategy {}, from {} to {}",
                username, stock.getSymbol(), request.getStrategyName(), request.getStartDate(), request.getEndDate());

        // 1. Fetch historical signals in range
        List<Signal> allSignals = signalRepository.findByStockIdAndDateRange(stock.getId(), request.getStartDate(), request.getEndDate());
        
        // 2. Filter signals based on selected strategy
        List<Signal> strategySignals = allSignals.stream()
                .filter(s -> matchesStrategy(s, request.getStrategyName()))
                .collect(Collectors.toList());

        // 3. Simulate trading
        double initialCapital = request.getInitialCapital() != null ? request.getInitialCapital() : 100000.0;
        double cash = initialCapital;
        double shares = 0.0;
        boolean inTrade = false;
        double buyPrice = 0.0;
        LocalDate buyDate = null;

        int totalTrades = 0;
        int winningTrades = 0;
        double peakValue = initialCapital;
        double maxDrawdown = 0.0;
        List<TradeLogDto> tradeLogs = new ArrayList<>();

        for (Signal signal : strategySignals) {
            boolean isBuy = signal.getSignalType() == Signal.SignalType.BUY;
            boolean isSell = signal.getSignalType() == Signal.SignalType.SELL;

            if (isBuy && !inTrade) {
                buyPrice = signal.getTriggerPrice();
                buyDate = signal.getSignalDate();
                shares = cash / buyPrice;
                cash = 0.0;
                inTrade = true;
                totalTrades++;
                
                tradeLogs.add(new TradeLogDto("BUY", buyDate, buyPrice, shares, shares * buyPrice, null));
            } else if (isSell && inTrade) {
                double sellPrice = signal.getTriggerPrice();
                LocalDate sellDate = signal.getSignalDate();
                double value = shares * sellPrice;
                cash = value;
                double profitPct = ((sellPrice - buyPrice) / buyPrice) * 100.0;
                if (profitPct > 0) {
                    winningTrades++;
                }

                tradeLogs.add(new TradeLogDto("SELL", sellDate, sellPrice, shares, value, profitPct));
                shares = 0.0;
                inTrade = false;

                if (cash > peakValue) {
                    peakValue = cash;
                }
                double dd = ((peakValue - cash) / peakValue) * 100.0;
                if (dd > maxDrawdown) {
                    maxDrawdown = dd;
                }
            }
        }

        // If still in a trade at the end, force sell at the last available closing price
        if (inTrade) {
            List<StockPrice> finalPrices = stockPriceRepository.findByStock_IdAndTradeDateBetweenOrderByTradeDateAsc(
                    stock.getId(), buyDate, request.getEndDate());
            if (!finalPrices.isEmpty()) {
                StockPrice lastPrice = finalPrices.get(finalPrices.size() - 1);
                double sellPrice = lastPrice.getClosePrice();
                LocalDate sellDate = lastPrice.getTradeDate();
                double value = shares * sellPrice;
                cash = value;
                double profitPct = ((sellPrice - buyPrice) / buyPrice) * 100.0;
                if (profitPct > 0) {
                    winningTrades++;
                }

                tradeLogs.add(new TradeLogDto("SELL (Exit)", sellDate, sellPrice, shares, value, profitPct));
                if (cash > peakValue) {
                    peakValue = cash;
                }
                double dd = ((peakValue - cash) / peakValue) * 100.0;
                if (dd > maxDrawdown) {
                    maxDrawdown = dd;
                }
            }
        }

        double totalReturnPct = ((cash - initialCapital) / initialCapital) * 100.0;
        double winRatePct = totalTrades > 0 ? ((double) winningTrades / totalTrades) * 100.0 : 0.0;

        // 4. Persist aggregate results to DB
        BacktestResult result = new BacktestResult(
                user,
                request.getStrategyName(),
                stock,
                request.getStartDate(),
                request.getEndDate(),
                totalReturnPct,
                winRatePct,
                totalTrades,
                maxDrawdown
        );
        result = backtestResultRepository.save(result);

        return new BacktestResultDto(
                result.getId(),
                result.getStrategyName(),
                stock.getSymbol(),
                result.getStartDate(),
                result.getEndDate(),
                result.getTotalReturnPct(),
                result.getWinRatePct(),
                result.getTotalTrades(),
                result.getMaxDrawdownPct(),
                tradeLogs,
                result.getCreatedAt()
        );
    }

    public List<BacktestResultDto> getHistoryForUser(String username) {
        List<BacktestResult> results = backtestResultRepository.findByUser_UsernameOrderByCreatedAtDesc(username);
        return results.stream()
                .map(r -> new BacktestResultDto(
                        r.getId(),
                        r.getStrategyName(),
                        r.getStock() != null ? r.getStock().getSymbol() : "ALL",
                        r.getStartDate(),
                        r.getEndDate(),
                        r.getTotalReturnPct(),
                        r.getWinRatePct(),
                        r.getTotalTrades(),
                        r.getMaxDrawdownPct(),
                        new ArrayList<>(), // details of past run logs not cached completely (only aggregates stored in db)
                        r.getCreatedAt()
                ))
                .collect(Collectors.toList());
    }

    private boolean matchesStrategy(Signal signal, String strategyName) {
        if (strategyName == null || signal.getStrategy() == null) return false;
        
        if (strategyName.equalsIgnoreCase("RSI_STRATEGY")) {
            return signal.getStrategy().equalsIgnoreCase("RSI_OVERSOLD") || 
                   signal.getStrategy().equalsIgnoreCase("RSI_OVERBOUGHT");
        }
        
        return signal.getStrategy().equalsIgnoreCase(strategyName);
    }
}
