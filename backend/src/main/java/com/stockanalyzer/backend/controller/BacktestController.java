package com.stockanalyzer.backend.controller;

import com.stockanalyzer.backend.dto.BacktestRequest;
import com.stockanalyzer.backend.dto.BacktestResultDto;
import com.stockanalyzer.backend.dto.MessageResponse;
import com.stockanalyzer.backend.service.BacktestService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/backtest")
public class BacktestController {

    @Autowired
    private BacktestService backtestService;

    @PostMapping
    public ResponseEntity<?> runBacktest(Principal principal, @Valid @RequestBody BacktestRequest request) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            BacktestResultDto result = backtestService.runBacktest(principal.getName(), request);
            return ResponseEntity.ok(result);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @GetMapping("/history")
    public ResponseEntity<List<BacktestResultDto>> getBacktestHistory(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(backtestService.getHistoryForUser(principal.getName()));
    }
}
