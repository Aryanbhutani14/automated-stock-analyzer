package com.stockanalyzer.service;

import com.stockanalyzer.dto.BacktestRequest;
import com.stockanalyzer.dto.BacktestResultDto;
import com.stockanalyzer.entity.BacktestResult;
import com.stockanalyzer.entity.Signal;
import com.stockanalyzer.entity.Stock;
import com.stockanalyzer.entity.StockPrice;
import com.stockanalyzer.entity.User;
import com.stockanalyzer.repository.BacktestResultRepository;
import com.stockanalyzer.repository.SignalRepository;
import com.stockanalyzer.repository.StockPriceRepository;
import com.stockanalyzer.repository.StockRepository;
import com.stockanalyzer.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.math.RoundingMode;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

/**
 * Historical backtesting engine.
 *
 * Simulation rules (simple long-only, full position):
 *  - BUY signal  → enter at the signal day's close price
 *  - SELL signal → exit  at the signal day's close price
 *  - One open position at a time (no pyramiding)
 *  - Tracks per-trade P&L, win rate, max drawdown
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class BacktestService {

    private final StockRepository        stockRepository;
    private final StockPriceRepository   priceRepository;
    private final SignalRepository       signalRepository;
    private final BacktestResultRepository backtestResultRepository;
    private final UserRepository         userRepository;

    // ─── Public API ───────────────────────────────────────────────────────────

    @Transactional
    public BacktestResultDto runBacktest(String email, BacktestRequest req) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));

        Stock stock = stockRepository.findBySymbolIgnoreCase(req.getSymbol())
                .orElseThrow(() -> new IllegalArgumentException("Stock not found: " + req.getSymbol()));

        // Fetch all signals for this stock in the date range
        List<Signal> signals = signalRepository.findByStockIdAndDateRange(
                stock.getId(), req.getStartDate(), req.getEndDate());

        if (signals.isEmpty()) {
            return BacktestResultDto.builder()
                    .symbol(req.getSymbol())
                    .strategy(req.getStrategy())
                    .startDate(req.getStartDate())
                    .endDate(req.getEndDate())
                    .totalTrades(0)
                    .totalReturnPct(BigDecimal.ZERO)
                    .winRatePct(BigDecimal.ZERO)
                    .maxDrawdownPct(BigDecimal.ZERO)
                    .message("No signals found for this strategy in the given date range")
                    .build();
        }

        // Filter by strategy if specified
        List<Signal> filtered = req.getStrategy() != null && !req.getStrategy().isBlank()
                ? signals.stream()
                    .filter(s -> s.getStrategy().equalsIgnoreCase(req.getStrategy()))
                    .toList()
                : signals;

        BacktestStats stats = simulate(filtered, req.getInitialCapital(), stock);

        // Persist result
        BacktestResult result = BacktestResult.builder()
                .user(user)
                .stock(stock)
                .strategyName(req.getStrategy() != null ? req.getStrategy() : "ALL")
                .startDate(req.getStartDate())
                .endDate(req.getEndDate())
                .totalReturnPct(stats.totalReturnPct)
                .winRatePct(stats.winRatePct)
                .totalTrades(stats.totalTrades)
                .maxDrawdownPct(stats.maxDrawdownPct)
                .build();
        backtestResultRepository.save(result);

        return BacktestResultDto.builder()
                .symbol(req.getSymbol())
                .strategy(req.getStrategy())
                .startDate(req.getStartDate())
                .endDate(req.getEndDate())
                .totalReturnPct(stats.totalReturnPct)
                .winRatePct(stats.winRatePct)
                .totalTrades(stats.totalTrades)
                .maxDrawdownPct(stats.maxDrawdownPct)
                .trades(stats.trades)
                .message("Backtest completed successfully")
                .build();
    }

    @Transactional(readOnly = true)
    public List<BacktestResultDto> getUserHistory(String email) {
        User user = userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found"));
        return backtestResultRepository.findByUser_IdOrderByCreatedAtDesc(user.getId())
                .stream().map(BacktestResultDto::fromEntity).toList();
    }

    // ─── Simulation engine ────────────────────────────────────────────────────

    private BacktestStats simulate(List<Signal> signals, BigDecimal initialCapital, Stock stock) {
        BigDecimal capital     = initialCapital != null ? initialCapital : new BigDecimal("100000");
        BigDecimal entryPrice  = null;
        BigDecimal peakCapital = capital;
        BigDecimal maxDrawdown = BigDecimal.ZERO;

        int wins = 0;
        int totalTrades = 0;
        List<BacktestResultDto.TradeRecord> trades = new ArrayList<>();

        for (Signal signal : signals) {
            BigDecimal close = getPriceOnDate(stock, signal.getSignalDate());
            if (close == null) continue;

            if (signal.getSignalType() == Signal.SignalType.BUY && entryPrice == null) {
                // Enter position
                entryPrice = close;

            } else if (signal.getSignalType() == Signal.SignalType.SELL && entryPrice != null) {
                // Exit position
                BigDecimal returnPct = close.subtract(entryPrice)
                        .divide(entryPrice, 6, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100));

                capital = capital.multiply(
                        BigDecimal.ONE.add(returnPct.divide(BigDecimal.valueOf(100), 6, RoundingMode.HALF_UP)));

                if (capital.compareTo(peakCapital) > 0) peakCapital = capital;

                BigDecimal drawdown = peakCapital.subtract(capital)
                        .divide(peakCapital, 6, RoundingMode.HALF_UP)
                        .multiply(BigDecimal.valueOf(100));
                if (drawdown.compareTo(maxDrawdown) > 0) maxDrawdown = drawdown;

                if (returnPct.compareTo(BigDecimal.ZERO) > 0) wins++;
                totalTrades++;

                trades.add(BacktestResultDto.TradeRecord.builder()
                        .entryDate(signal.getSignalDate())
                        .exitDate(signal.getSignalDate())
                        .entryPrice(entryPrice)
                        .exitPrice(close)
                        .returnPct(returnPct.setScale(2, RoundingMode.HALF_UP))
                        .build());

                entryPrice = null;
            }
        }

        BigDecimal totalReturnPct = capital.subtract(initialCapital != null ? initialCapital : new BigDecimal("100000"))
                .divide(initialCapital != null ? initialCapital : new BigDecimal("100000"), 4, RoundingMode.HALF_UP)
                .multiply(BigDecimal.valueOf(100))
                .setScale(2, RoundingMode.HALF_UP);

        BigDecimal winRatePct = totalTrades > 0
                ? BigDecimal.valueOf(wins * 100.0 / totalTrades).setScale(2, RoundingMode.HALF_UP)
                : BigDecimal.ZERO;

        return new BacktestStats(
                totalReturnPct,
                winRatePct,
                totalTrades,
                maxDrawdown.setScale(2, RoundingMode.HALF_UP),
                trades
        );
    }

    private BigDecimal getPriceOnDate(Stock stock, java.time.LocalDate date) {
        return priceRepository.findByStock_IdAndTradeDate(stock.getId(), date)
                .map(StockPrice::getClosePrice)
                .orElse(null);
    }

    // ─── Internal record ──────────────────────────────────────────────────────

    private record BacktestStats(
            BigDecimal totalReturnPct,
            BigDecimal winRatePct,
            int totalTrades,
            BigDecimal maxDrawdownPct,
            List<BacktestResultDto.TradeRecord> trades
    ) {}
}
