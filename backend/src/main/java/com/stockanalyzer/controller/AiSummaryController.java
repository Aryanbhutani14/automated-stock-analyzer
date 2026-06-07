package com.stockanalyzer.controller;

import com.stockanalyzer.dto.AiSummaryDto;
import com.stockanalyzer.service.AiSummaryService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

/**
 * GET /api/ai/summary/{symbol}
 *
 * Returns today's AI summary from DB if available,
 * otherwise generates one on demand via OpenAI.
 */
@RestController
@RequestMapping("/api/ai")
@RequiredArgsConstructor
public class AiSummaryController {

    private final AiSummaryService aiSummaryService;

    @GetMapping("/summary/{symbol}")
    public ResponseEntity<AiSummaryDto> getSummary(@PathVariable String symbol) {
        return aiSummaryService.getSummaryForStock(symbol)
                .map(AiSummaryDto::from)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }
}
