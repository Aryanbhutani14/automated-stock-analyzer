package com.stockanalyzer.backend.controller;

import com.stockanalyzer.backend.dto.AiSummaryDto;
import com.stockanalyzer.backend.dto.MessageResponse;
import com.stockanalyzer.backend.service.AiSummaryService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;

@RestController
@RequestMapping("/api/ai")
public class AiSummaryController {

    @Autowired
    private AiSummaryService aiSummaryService;

    @GetMapping("/summary/{symbol}")
    public ResponseEntity<?> getStockSummary(Principal principal, @PathVariable String symbol) {
        if (principal == null) {
            return ResponseEntity.status(401).body(new MessageResponse("Error: Unauthorized"));
        }
        try {
            AiSummaryDto summary = aiSummaryService.getSummaryForStock(symbol);
            return ResponseEntity.ok(summary);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }
}
