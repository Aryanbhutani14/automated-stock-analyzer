package com.stockanalyzer.backend.service;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.stockanalyzer.backend.dto.AiSummaryDto;
import com.stockanalyzer.backend.model.AiSummary;
import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import com.stockanalyzer.backend.model.TechnicalIndicator;
import com.stockanalyzer.backend.repository.AiSummaryRepository;
import com.stockanalyzer.backend.repository.StockPriceRepository;
import com.stockanalyzer.backend.repository.StockRepository;
import com.stockanalyzer.backend.repository.TechnicalIndicatorRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.MediaType;
import org.springframework.http.ResponseEntity;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.client.RestTemplate;
import java.time.LocalDate;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;

@Service
@Transactional
public class AiSummaryService {

    private static final Logger logger = LoggerFactory.getLogger(AiSummaryService.class);

    @Value("${app.api.openai.key:}")
    private String openAiApiKey;

    @Autowired
    private AiSummaryRepository aiSummaryRepository;

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private StockPriceRepository stockPriceRepository;

    @Autowired
    private TechnicalIndicatorRepository indicatorRepository;

    private final RestTemplate restTemplate = new RestTemplate();
    private final ObjectMapper objectMapper = new ObjectMapper();

    public AiSummaryDto getSummaryForStock(String symbol) {
        Stock stock = stockRepository.findBySymbolIgnoreCase(symbol)
                .orElseThrow(() -> new IllegalArgumentException("Stock not found with symbol: " + symbol));

        LocalDate today = LocalDate.now();
        Optional<AiSummary> cached = aiSummaryRepository.findByStock_IdAndSummaryDate(stock.getId(), today);
        if (cached.isPresent()) {
            return convertToDto(cached.get());
        }

        // Generate and cache
        AiSummary newSummary = generateSummary(stock, today);
        newSummary = aiSummaryRepository.save(newSummary);
        return convertToDto(newSummary);
    }

    public void generateForAllStocks() {
        List<Stock> stocks = stockRepository.findByIsActiveTrue();
        logger.info("Generating AI summaries for {} active stocks...", stocks.size());
        LocalDate today = LocalDate.now();

        int generated = 0;
        for (Stock stock : stocks) {
            try {
                Optional<AiSummary> cached = aiSummaryRepository.findByStock_IdAndSummaryDate(stock.getId(), today);
                if (cached.isPresent()) continue;

                AiSummary newSummary = generateSummary(stock, today);
                aiSummaryRepository.save(newSummary);
                generated++;
                // Add minor rate limit delay
                Thread.sleep(1000);
            } catch (Exception e) {
                logger.error("Failed to generate AI summary for {}: {}", stock.getSymbol(), e.getMessage());
            }
        }
        logger.info("AI summaries generation complete - {} new profiles saved.", generated);
    }

    private AiSummary generateSummary(Stock stock, LocalDate date) {
        Optional<StockPrice> latestPriceOpt = stockPriceRepository.findFirstByStockOrderByTradeDateDesc(stock);
        Optional<TechnicalIndicator> latestIndicatorOpt = indicatorRepository.findLatestByStockId(stock.getId());

        Double closePrice = latestPriceOpt.map(StockPrice::getClosePrice).orElse(null);
        Double ma50 = latestIndicatorOpt.map(TechnicalIndicator::getMa50).orElse(null);
        Double ma220 = latestIndicatorOpt.map(TechnicalIndicator::getMa220).orElse(null);
        Double rsi = latestIndicatorOpt.map(TechnicalIndicator::getRsi14).orElse(null);
        Double high52 = latestIndicatorOpt.map(TechnicalIndicator::getWeek52High).orElse(null);
        Double low52 = latestIndicatorOpt.map(TechnicalIndicator::getWeek52Low).orElse(null);

        // Build summary offline if key is not configured
        if (openAiApiKey == null || openAiApiKey.trim().isEmpty() || openAiApiKey.equals("YOUR_OPENAI_API_KEY")) {
            logger.info("OpenAI API key is missing. Using dynamic offline template for {}", stock.getSymbol());
            String text = buildFallbackSummaryText(stock, closePrice, ma50, ma220, rsi, low52, high52);
            return new AiSummary(stock, date, text, "offline-fallback-generator");
        }

        try {
            String prompt = String.format(
                "Act as a professional financial analyst. Summarize the stock profile, recent price performance, and technical outlook of %s (%s) in sector %s, industry %s. " +
                "Key metrics: Latest Close Price: ₹%s, 52-week High: ₹%s, 52-week Low: ₹%s, RSI(14): %s, 50-day Simple Moving Average: ₹%s, 220-day Simple Moving Average: ₹%s. " +
                "Provide a concise 2-3 paragraph summary. Highlight if it's currently bullish, bearish, or neutral technically, and its core business outline. Don't mention specific target numbers that are purely speculative. Keep it factual based on the metrics.",
                stock.getName(), stock.getSymbol(), stock.getSector(), stock.getIndustry(),
                closePrice != null ? String.format("%.2f", closePrice) : "N/A",
                high52 != null ? String.format("%.2f", high52) : "N/A",
                low52 != null ? String.format("%.2f", low52) : "N/A",
                rsi != null ? String.format("%.1f", rsi) : "N/A",
                ma50 != null ? String.format("%.2f", ma50) : "N/A",
                ma220 != null ? String.format("%.2f", ma220) : "N/A"
            );

            HttpHeaders headers = new HttpHeaders();
            headers.setContentType(MediaType.APPLICATION_JSON);
            headers.setBearerAuth(openAiApiKey);

            Map<String, Object> body = new HashMap<>();
            body.put("model", "gpt-4o-mini");
            body.put("messages", List.of(Map.of("role", "user", "content", prompt)));
            body.put("temperature", 0.7);

            HttpEntity<Map<String, Object>> entity = new HttpEntity<>(body, headers);
            ResponseEntity<String> response = restTemplate.postForEntity("https://api.openai.com/v1/chat/completions", entity, String.class);

            if (response.getStatusCode().is2xxSuccessful() && response.getBody() != null) {
                JsonNode root = objectMapper.readTree(response.getBody());
                String resultText = root.path("choices").get(0).path("message").path("content").asText();
                return new AiSummary(stock, date, resultText.trim(), "gpt-4o-mini");
            }
        } catch (Exception e) {
            logger.warn("OpenAI API call failed for {}: {}. Falling back to offline text.", stock.getSymbol(), e.getMessage());
        }

        String text = buildFallbackSummaryText(stock, closePrice, ma50, ma220, rsi, low52, high52);
        return new AiSummary(stock, date, text, "offline-fallback-generator");
    }

    private String buildFallbackSummaryText(Stock stock, Double closePrice, Double ma50, Double ma220, Double rsi, Double low52, Double high52) {
        StringBuilder sb = new StringBuilder();
        sb.append(stock.getName()).append(" (").append(stock.getSymbol()).append(") is a prominent firm operating in the ");
        sb.append(stock.getSector() != null ? stock.getSector() : "financial").append(" sector, and categorised under the ");
        sb.append(stock.getIndustry() != null ? stock.getIndustry() : "general").append(" industry. ");

        if (closePrice != null) {
            sb.append("Technically, the stock is currently trading at ₹").append(String.format("%.2f", closePrice)).append(". ");
        }

        if (rsi != null) {
            sb.append("Its 14-day Relative Strength Index (RSI) stands at ").append(String.format("%.1f", rsi)).append(", ");
            if (rsi < 35) {
                sb.append("indicating that the stock is in oversold territory, which could attract value buyers seeking a short-term rebound. ");
            } else if (rsi > 70) {
                sb.append("indicating that the stock is in overbought territory, suggesting potential caution or consolidation in the near term. ");
            } else {
                sb.append("suggesting a relatively neutral trend without extreme buying or selling pressure. ");
            }
        }

        if (ma50 != null && ma220 != null) {
            sb.append("Comparing the moving averages, the 50-day Simple Moving Average (SMA) is at ₹").append(String.format("%.2f", ma50));
            sb.append(" and the 220-day SMA is at ₹").append(String.format("%.2f", ma220)).append(". ");
            if (closePrice != null) {
                if (closePrice > ma50 && ma50 > ma220) {
                    sb.append("The current trend appears bullish as the price sits above both key moving averages, showing positive momentum. ");
                } else if (closePrice < ma50 && ma50 < ma220) {
                    sb.append("The current trend appears bearish as the price is trading below both the medium and long term moving averages. ");
                } else {
                    sb.append("The moving averages point to a mixed technical posture with intermediate consolidation patterns. ");
                }
            }
        }

        if (low52 != null && high52 != null) {
            sb.append("Over the past 52 weeks, the stock has registered a low of ₹").append(String.format("%.2f", low52));
            sb.append(" and reached a high of ₹").append(String.format("%.2f", high52)).append(". ");
        }

        sb.append("This profile represents a quantitative technical summary. For deep structural evaluations, investors should analyze corporate balance sheets, operational updates, and quarterly performance announcements.");
        return sb.toString();
    }

    private AiSummaryDto convertToDto(AiSummary summary) {
        return new AiSummaryDto(
                summary.getStock().getSymbol(),
                summary.getSummaryText(),
                summary.getSummaryDate(),
                summary.getModelUsed()
        );
    }
}
