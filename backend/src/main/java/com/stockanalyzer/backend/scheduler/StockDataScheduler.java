package com.stockanalyzer.backend.scheduler;

import com.stockanalyzer.backend.service.SignalService;
import com.stockanalyzer.backend.service.TechnicalIndicatorService;
import com.stockanalyzer.backend.service.YahooFinanceService;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.time.LocalDateTime;

@Component
public class StockDataScheduler {

    private static final Logger logger = LoggerFactory.getLogger(StockDataScheduler.class);

    @Autowired
    private YahooFinanceService yahooFinanceService;

    @Autowired
    private TechnicalIndicatorService indicatorService;

    @Autowired
    private SignalService signalService;

    @Autowired
    private com.stockanalyzer.backend.service.AlertNotificationService alertNotificationService;

    @Autowired
    private com.stockanalyzer.backend.service.AiSummaryService aiSummaryService;

    /**
     * Full daily pipeline - runs automatically on weekdays at 6:30 PM IST (1:00 PM UTC).
     */
    @Scheduled(cron = "${app.scheduler.data-fetch-cron:0 0 13 * * MON-FRI}")
    public void runDailyPipeline() {
        logger.info("==========================================");
        logger.info(" Daily Stock Pipeline started at {}", LocalDateTime.now());
        logger.info("==========================================");

        try {
            // Step 1: Sync price data from Yahoo Finance
            logger.info("Step 1/5 -- Fetching market data from Yahoo Finance");
            yahooFinanceService.syncAllActiveStocks();

            // Step 2: Calculate technical indicators
            logger.info("Step 2/5 -- Calculating technical indicators");
            indicatorService.calculateForAllStocks();

            // Step 3: Generate BUY/SELL signals
            logger.info("Step 3/5 -- Generating buy/sell signals");
            signalService.generateSignalsForAllStocks();

            // Step 4: Process active alerts
            logger.info("Step 4/5 -- Evaluating user conditional alerts");
            alertNotificationService.processAllAlerts();

            // Step 5: Refresh AI summaries
            logger.info("Step 5/5 -- Refreshing AI summaries");
            aiSummaryService.generateForAllStocks();

            logger.info("Daily pipeline completed successfully at {}", LocalDateTime.now());
        } catch (Exception e) {
            logger.error("Daily pipeline failed: {}", e.getMessage(), e);
        }
        logger.info("==========================================");
    }

    /**
     * Manual trigger endpoint. Runs the pipeline asynchronously in a background thread.
     */
    public void triggerManually() {
        logger.info("Manual pipeline trigger requested. Executing asynchronously...");
        runDailyPipeline();
    }
}
