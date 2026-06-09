package com.stockanalyzer.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import com.stockanalyzer.backend.repository.StockPriceRepository;
import com.stockanalyzer.backend.repository.StockRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;
import java.time.Instant;
import java.time.LocalDate;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
public class YahooFinanceService {
    private static final Logger logger = LoggerFactory.getLogger(YahooFinanceService.class);
    
    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private StockPriceRepository stockPriceRepository;

    public void syncStockData(String symbol) {
        Stock stock = stockRepository.findBySymbol(symbol)
                .orElseThrow(() -> new IllegalArgumentException("Stock not found with symbol: " + symbol));

        String url = String.format("https://query1.finance.yahoo.com/v8/finance/chart/%s?range=1y&interval=1d", symbol);

        try {
            logger.info("Fetching Yahoo Finance data for: {}", symbol);
            org.springframework.http.HttpHeaders headers = new org.springframework.http.HttpHeaders();
            headers.set("User-Agent", "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Safari/537.36");
            org.springframework.http.HttpEntity<String> entity = new org.springframework.http.HttpEntity<>(headers);
            
            ResponseEntity<String> response = restTemplate.exchange(url, org.springframework.http.HttpMethod.GET, entity, String.class);
            
            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                JsonNode resultNode = root.path("chart").path("result").get(0);
                
                if (resultNode == null) {
                    logger.warn("No chart results returned for symbol: {}", symbol);
                    return;
                }

                JsonNode timestamps = resultNode.path("timestamp");
                JsonNode quote = resultNode.path("indicators").path("quote").get(0);
                
                if (timestamps.isMissingNode() || quote == null) {
                    logger.warn("Missing timestamp or quotes data for symbol: {}", symbol);
                    return;
                }

                JsonNode opens = quote.path("open");
                JsonNode highs = quote.path("high");
                JsonNode lows = quote.path("low");
                JsonNode closes = quote.path("close");
                JsonNode volumes = quote.path("volume");

                List<StockPrice> priceList = new ArrayList<>();

                for (int i = 0; i < timestamps.size(); i++) {
                    long epochSecond = timestamps.get(i).asLong();
                    LocalDate date = Instant.ofEpochSecond(epochSecond)
                            .atZone(ZoneId.systemDefault())
                            .toLocalDate();

                    // Skip if close price is null/invalid
                    if (closes.get(i).isNull() || closes.get(i).isMissingNode()) {
                        continue;
                    }

                    double open = opens.get(i).asDouble();
                    double high = highs.get(i).asDouble();
                    double low = lows.get(i).asDouble();
                    double close = closes.get(i).asDouble();
                    long volume = volumes.get(i).asLong();

                    // Upsert pricing record
                    Optional<StockPrice> existingPrice = stockPriceRepository.findByStockAndTradeDate(stock, date);
                    StockPrice stockPrice;
                    if (existingPrice.isPresent()) {
                        stockPrice = existingPrice.get();
                        stockPrice.setOpenPrice(open);
                        stockPrice.setHighPrice(high);
                        stockPrice.setLowPrice(low);
                        stockPrice.setClosePrice(close);
                        stockPrice.setVolume(volume);
                    } else {
                        stockPrice = new StockPrice(stock, date, open, high, low, close, volume);
                    }
                    priceList.add(stockPrice);
                }

                stockPriceRepository.saveAll(priceList);
                logger.info("Successfully synced {} price data points for {}", priceList.size(), symbol);
            }
        } catch (Exception e) {
            logger.error("Error syncing stock data for {}: {}", symbol, e.getMessage());
        }
    }

    public void syncAllActiveStocks() {
        List<Stock> activeStocks = stockRepository.findAll().stream()
                .filter(Stock::getIsActive)
                .toList();

        logger.info("Starting bulk sync for {} active stocks", activeStocks.size());
        for (Stock stock : activeStocks) {
            try {
                syncStockData(stock.getSymbol());
                // Mild rate-limiting delay between requests
                Thread.sleep(1000);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                logger.error("Sync interrupted: {}", e.getMessage());
                break;
            }
        }
    }
}
