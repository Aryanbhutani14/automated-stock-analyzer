package com.stockanalyzer.scheduler;

import com.stockanalyzer.service.SignalService;
import com.stockanalyzer.service.StockDataFetchService;
import com.stockanalyzer.service.TechnicalIndicatorService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

/**
 * Orchestrates the full daily data pipeline.
 *
 * Pipeline order (runs every weekday after market close):
 *  1. Fetch OHLCV data from Alpha Vantage
 *  2. Calculate technical indicators (MA, RSI, Volume, Momentum)
 *  3. Generate buy/sell signals
 *
 * Cron: 0 0 13 * * MON-FRI  →  1:00 PM UTC  ≈  6:30 PM IST
 *
 * AI summaries and email alerts are triggered separately
 * after signals are available (Phase 3).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class StockDataScheduler {

    private final StockDataFetchService      fetchService;
    private final TechnicalIndicatorService  indicatorService;
    private final SignalService              signalService;

    /**
     * Full daily pipeline — runs automatically on weekdays at 6:30 PM IST.
     */
    @Scheduled(cron = "${app.scheduler.data-fetch-cron}")
    public void runDailyPipeline() {
        log.info("═══════════════════════════════════════════");
        log.info(" Daily Stock Pipeline started at {}", LocalDateTime.now());
        log.info("═══════════════════════════════════════════");

        try {
            // Step 1 — Fetch OHLCV
            log.info("Step 1/3 ── Fetching market data");
            fetchService.fetchAndStoreAllStocks();

            // Step 2 — Calculate indicators
            log.info("Step 2/3 ── Calculating technical indicators");
            indicatorService.calculateForAllStocks();

            // Step 3 — Generate signals
            log.info("Step 3/3 ── Generating buy/sell signals");
            signalService.generateSignalsForAllStocks();

            log.info("Daily pipeline completed successfully at {}", LocalDateTime.now());

        } catch (Exception e) {
            log.error("Daily pipeline failed: {}", e.getMessage(), e);
        }

        log.info("═══════════════════════════════════════════");
    }

    /**
     * Manual trigger endpoint — can be called via the admin API
     * to run the pipeline outside of the scheduled window.
     */
    public void triggerManually() {
        log.info("Manual pipeline trigger requested");
        runDailyPipeline();
    }
}
