package com.stockanalyzer.controller;

import com.stockanalyzer.dto.BacktestRequest;
import com.stockanalyzer.dto.BacktestResultDto;
import com.stockanalyzer.service.BacktestService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * POST /api/backtest         — run a new backtest
 * GET  /api/backtest/history — get current user's past backtest results
 */
@RestController
@RequestMapping("/api/backtest")
@RequiredArgsConstructor
public class BacktestController {

    private final BacktestService backtestService;

    @PostMapping
    public ResponseEntity<BacktestResultDto> runBacktest(
            @AuthenticationPrincipal UserDetails user,
            @Valid @RequestBody BacktestRequest req) {
        return ResponseEntity.ok(backtestService.runBacktest(user.getUsername(), req));
    }

    @GetMapping("/history")
    public ResponseEntity<List<BacktestResultDto>> getHistory(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(backtestService.getUserHistory(user.getUsername()));
    }
}
