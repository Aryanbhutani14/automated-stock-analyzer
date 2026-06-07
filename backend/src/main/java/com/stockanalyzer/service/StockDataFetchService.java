package com.stockanalyzer.service;

import com.stockanalyzer.entity.Stock;
import com.stockanalyzer.entity.StockPrice;
import com.stockanalyzer.repository.StockPriceRepository;
import com.stockanalyzer.repository.StockRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Map;

/**
 * Fetches daily OHLCV data from Alpha Vantage and stores it in stock_prices.
 *
 * Alpha Vantage endpoint used:
 *   TIME_SERIES_DAILY_ADJUSTED — returns up to 100 trading days by default.
 *
 * Free-tier rate limit: 25 requests/day — we batch all stocks but respect the limit.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class StockDataFetchService {

    private final StockRepository stockRepository;
    private final StockPriceRepository stockPriceRepository;
    private final WebClient.Builder webClientBuilder;

    @Value("${app.api.alpha-vantage.key}")
    private String alphaVantageKey;

    private static final String BASE_URL = "https://www.alphavantage.co/query";
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ISO_LOCAL_DATE;

    // ─── Public API ───────────────────────────────────────────────────────────

    /**
     * Called by the daily scheduler. Fetches and stores today's price for every active stock.
     */
    @Transactional
    public void fetchAndStoreAllStocks() {
        List<Stock> activeStocks = stockRepository.findByActiveTrue();
        log.info("Starting daily data fetch for {} active stocks", activeStocks.size());

        int success = 0;
        int skipped = 0;
        int failed  = 0;

        for (Stock stock : activeStocks) {
            try {
                boolean saved = fetchAndStoreStock(stock);
                if (saved) success++; else skipped++;
                // Respect Alpha Vantage free-tier: 5 req/min → ~12 s between calls
                Thread.sleep(12_000);
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
                log.warn("Fetch loop interrupted");
                break;
            } catch (Exception e) {
                log.error("Failed to fetch data for {}: {}", stock.getSymbol(), e.getMessage());
                failed++;
            }
        }
        log.info("Data fetch complete — saved={}, skipped={}, failed={}", success, skipped, failed);
    }

    /**
     * Fetch and store a single stock's latest daily price.
     *
     * @return true if a new row was inserted, false if already present for today
     */
    @Transactional
    public boolean fetchAndStoreStock(Stock stock) {
        LocalDate today = LocalDate.now();

        if (stockPriceRepository.existsByStock_IdAndTradeDate(stock.getId(), today)) {
            log.debug("Price already loaded for {} on {}", stock.getSymbol(), today);
            return false;
        }

        Map<String, Object> response = fetchDailyTimeSeries(stock.getSymbol());
        if (response == null) return false;

        @SuppressWarnings("unchecked")
        Map<String, Map<String, String>> timeSeries =
                (Map<String, Map<String, String>>) response.get("Time Series (Daily)");

        if (timeSeries == null || timeSeries.isEmpty()) {
            log.warn("Empty time series for {}", stock.getSymbol());
            return false;
        }

        // Most recent date key
        String latestDateStr = timeSeries.keySet().stream()
                .max(String::compareTo)
                .orElse(null);

        if (latestDateStr == null) return false;

        LocalDate latestDate = LocalDate.parse(latestDateStr, DATE_FMT);

        // Skip if data is older than yesterday (weekend / holiday)
        if (latestDate.isBefore(today.minusDays(3))) {
            log.info("No new trading data for {} — latest date is {}", stock.getSymbol(), latestDate);
            return false;
        }

        Map<String, String> ohlcv = timeSeries.get(latestDateStr);
        StockPrice price = StockPrice.builder()
                .stock(stock)
                .tradeDate(latestDate)
                .openPrice(parseDecimal(ohlcv.get("1. open")))
                .highPrice(parseDecimal(ohlcv.get("2. high")))
                .lowPrice(parseDecimal(ohlcv.get("3. low")))
                .closePrice(parseDecimal(ohlcv.get("4. close")))
                .adjClose(parseDecimal(ohlcv.get("5. adjusted close")))
                .volume(parseLong(ohlcv.get("6. volume")))
                .build();

        stockPriceRepository.save(price);
        log.info("Saved price for {} on {}: close={}", stock.getSymbol(), latestDate, price.getClosePrice());
        return true;
    }

    // ─── Internal helpers ─────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private Map<String, Object> fetchDailyTimeSeries(String symbol) {
        try {
            return webClientBuilder.baseUrl(BASE_URL).build()
                    .get()
                    .uri(uri -> uri
                            .queryParam("function", "TIME_SERIES_DAILY_ADJUSTED")
                            .queryParam("symbol", symbol)
                            .queryParam("outputsize", "compact")  // last 100 trading days
                            .queryParam("apikey", alphaVantageKey)
                            .build())
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();
        } catch (Exception e) {
            log.error("HTTP error fetching {} from Alpha Vantage: {}", symbol, e.getMessage());
            return null;
        }
    }

    private BigDecimal parseDecimal(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return new BigDecimal(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }

    private Long parseLong(String value) {
        if (value == null || value.isBlank()) return null;
        try {
            return Long.parseLong(value.trim());
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
