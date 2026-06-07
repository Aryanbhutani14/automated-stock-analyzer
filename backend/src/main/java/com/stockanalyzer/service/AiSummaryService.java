package com.stockanalyzer.service;

import com.stockanalyzer.entity.AiSummary;
import com.stockanalyzer.entity.Stock;
import com.stockanalyzer.entity.TechnicalIndicator;
import com.stockanalyzer.repository.AiSummaryRepository;
import com.stockanalyzer.repository.StockPriceRepository;
import com.stockanalyzer.repository.StockRepository;
import com.stockanalyzer.repository.TechnicalIndicatorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.reactive.function.client.WebClient;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.util.List;
import java.util.Map;
import java.util.Optional;

/**
 * Generates natural-language stock summaries via the OpenAI Chat Completions API.
 *
 * The prompt is crafted from live indicator data so each summary is grounded
 * in actual numbers, not hallucinated.
 *
 * Model used: gpt-4o-mini (fast, cheap, sufficient for this task)
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AiSummaryService {

    private static final String OPENAI_URL = "https://api.openai.com/v1/chat/completions";
    private static final String MODEL      = "gpt-4o-mini";

    private final StockRepository              stockRepository;
    private final StockPriceRepository         priceRepository;
    private final TechnicalIndicatorRepository indicatorRepository;
    private final AiSummaryRepository          summaryRepository;
    private final WebClient.Builder            webClientBuilder;

    @Value("${app.api.openai.key}")
    private String openAiKey;

    // ─── Public API ───────────────────────────────────────────────────────────

    /**
     * Generate and store AI summaries for all active stocks.
     * Skips stocks that already have a summary for today.
     * Called from the daily scheduler.
     */
    @Transactional
    public void generateForAllStocks() {
        List<Stock> stocks = stockRepository.findByActiveTrue();
        log.info("Generating AI summaries for {} stocks", stocks.size());
        int ok = 0;
        for (Stock stock : stocks) {
            try {
                generateAndStore(stock);
                ok++;
                Thread.sleep(500); // respect OpenAI rate limits
            } catch (InterruptedException ie) {
                Thread.currentThread().interrupt();
                break;
            } catch (Exception e) {
                log.error("AI summary failed for {}: {}", stock.getSymbol(), e.getMessage());
            }
        }
        log.info("AI summaries done — generated={}", ok);
    }

    /**
     * Get the latest AI summary for a stock (from DB), or generate one on demand.
     */
    @Transactional
    public Optional<AiSummary> getSummaryForStock(String symbol) {
        return stockRepository.findBySymbolIgnoreCase(symbol).map(stock -> {
            // Return today's summary if it exists
            Optional<AiSummary> existing = summaryRepository
                    .findByStock_IdAndSummaryDate(stock.getId(), LocalDate.now());
            if (existing.isPresent()) return existing.get();

            // Otherwise generate fresh
            return generateAndStore(stock);
        });
    }

    // ─── Core generation ─────────────────────────────────────────────────────

    @Transactional
    public AiSummary generateAndStore(Stock stock) {
        LocalDate today = LocalDate.now();

        Optional<AiSummary> existing = summaryRepository
                .findByStock_IdAndSummaryDate(stock.getId(), today);
        if (existing.isPresent()) return existing.get();

        var priceOpt = priceRepository.findLatestByStockId(stock.getId());
        var indOpt   = indicatorRepository.findLatestByStockId(stock.getId());

        if (priceOpt.isEmpty()) {
            log.debug("No price data for {} — skipping AI summary", stock.getSymbol());
            return null;
        }

        var price     = priceOpt.get();
        var indicator = indOpt.orElse(null);

        String prompt = buildPrompt(stock, price.getClosePrice(), indicator);
        String summaryText = callOpenAi(prompt);

        if (summaryText == null || summaryText.isBlank()) {
            log.warn("Empty AI response for {}", stock.getSymbol());
            return null;
        }

        AiSummary summary = AiSummary.builder()
                .stock(stock)
                .summaryDate(today)
                .summaryText(summaryText)
                .modelUsed(MODEL)
                .build();

        return summaryRepository.save(summary);
    }

    // ─── Prompt builder ───────────────────────────────────────────────────────

    private String buildPrompt(Stock stock, BigDecimal close, TechnicalIndicator ind) {
        StringBuilder sb = new StringBuilder();
        sb.append("You are a professional stock analyst. Write a concise, factual 3-sentence ")
          .append("analysis of ").append(stock.getName())
          .append(" (").append(stock.getSymbol()).append(") ")
          .append("based on the following technical data. ")
          .append("Do not give investment advice. Just describe the trend.\n\n");

        sb.append("Current Price: ₹").append(close != null ? close.toPlainString() : "N/A").append("\n");

        if (ind != null) {
            appendIfNotNull(sb, "50-Day MA",       ind.getMa50());
            appendIfNotNull(sb, "220-Day MA",      ind.getMa220());
            appendIfNotNull(sb, "RSI (14)",        ind.getRsi14());
            appendIfNotNull(sb, "52-Week High",    ind.getWeek52High());
            appendIfNotNull(sb, "52-Week Low",     ind.getWeek52Low());
            appendIfNotNull(sb, "Momentum Score",  ind.getMomentumScore());
            if (ind.getVolumeAvg20() != null)
                sb.append("20-Day Avg Volume: ").append(ind.getVolumeAvg20()).append("\n");

            // Contextual signals
            if (ind.getMa220() != null && close != null) {
                sb.append("Price vs 220-DMA: ").append(
                        close.compareTo(ind.getMa220()) > 0 ? "ABOVE (bullish)" : "BELOW (bearish)").append("\n");
            }
            if (ind.getMa50() != null && close != null) {
                sb.append("Price vs 50-DMA: ").append(
                        close.compareTo(ind.getMa50()) > 0 ? "ABOVE (bullish)" : "BELOW (bearish)").append("\n");
            }
        }

        sb.append("\nSector: ").append(stock.getSector())
          .append("\nExchange: ").append(stock.getExchange());

        return sb.toString();
    }

    private void appendIfNotNull(StringBuilder sb, String label, BigDecimal val) {
        if (val != null) sb.append(label).append(": ₹").append(val.toPlainString()).append("\n");
    }

    // ─── OpenAI call ─────────────────────────────────────────────────────────

    @SuppressWarnings("unchecked")
    private String callOpenAi(String prompt) {
        try {
            Map<String, Object> requestBody = Map.of(
                    "model",    MODEL,
                    "messages", List.of(Map.of("role", "user", "content", prompt)),
                    "max_tokens", 200,
                    "temperature", 0.4
            );

            Map<String, Object> response = webClientBuilder.build()
                    .post()
                    .uri(OPENAI_URL)
                    .header("Authorization", "Bearer " + openAiKey)
                    .header("Content-Type", "application/json")
                    .bodyValue(requestBody)
                    .retrieve()
                    .bodyToMono(Map.class)
                    .block();

            if (response == null) return null;

            List<Map<String, Object>> choices =
                    (List<Map<String, Object>>) response.get("choices");
            if (choices == null || choices.isEmpty()) return null;

            Map<String, Object> message = (Map<String, Object>) choices.get(0).get("message");
            return message != null ? (String) message.get("content") : null;

        } catch (Exception e) {
            log.error("OpenAI API call failed: {}", e.getMessage());
            return null;
        }
    }
}
