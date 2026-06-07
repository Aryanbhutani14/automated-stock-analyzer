package com.stockanalyzer.scheduler;

import com.stockanalyzer.service.AiSummaryService;
import com.stockanalyzer.service.AlertNotificationService;
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
 *  4. Process alert notifications (email)
 *  5. Generate AI stock summaries
 *
 * Cron: 0 0 13 * * MON-FRI  →  1:00 PM UTC  ≈  6:30 PM IST
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class StockDataScheduler {

    private final StockDataFetchService      fetchService;
    private final TechnicalIndicatorService  indicatorService;
    private final SignalService              signalService;
    private final AlertNotificationService   alertNotificationService;
    private final AiSummaryService           aiSummaryService;

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
            log.info("Step 1/5 ── Fetching market data");
            fetchService.fetchAndStoreAllStocks();

            // Step 2 — Calculate indicators
            log.info("Step 2/5 ── Calculating technical indicators");
            indicatorService.calculateForAllStocks();

            // Step 3 — Generate signals
            log.info("Step 3/5 ── Generating buy/sell signals");
            signalService.generateSignalsForAllStocks();

            // Step 4 — Process alert notifications
            log.info("Step 4/5 ── Processing user alerts");
            alertNotificationService.processAllAlerts();

            // Step 5 — AI summaries
            log.info("Step 5/5 ── Generating AI summaries");
            aiSummaryService.generateForAllStocks();

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
