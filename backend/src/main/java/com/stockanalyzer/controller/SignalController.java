package com.stockanalyzer.controller;

import com.stockanalyzer.entity.Signal;
import com.stockanalyzer.entity.Signal.SignalType;
import com.stockanalyzer.repository.SignalRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * REST endpoints for buy/sell signals.
 *
 * GET /api/signals?date=2026-06-07&type=BUY
 * GET /api/signals/{symbol}
 */
@RestController
@RequestMapping("/api/signals")
@RequiredArgsConstructor
public class SignalController {

    private final SignalRepository signalRepository;

    @GetMapping
    public ResponseEntity<List<Signal>> getSignalsByDate(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String type) {

        LocalDate targetDate = date != null ? date : LocalDate.now();

        if (type != null) {
            SignalType signalType = SignalType.valueOf(type.toUpperCase());
            return ResponseEntity.ok(
                    signalRepository.findBySignalTypeAndSignalDateOrderByStock_SymbolAsc(
                            signalType, targetDate));
        }
        return ResponseEntity.ok(
                signalRepository.findBySignalDateOrderByStock_SymbolAsc(targetDate));
    }

    @GetMapping("/{symbol}")
    public ResponseEntity<List<Signal>> getSignalsByStock(@PathVariable String symbol) {
        return ResponseEntity.ok(
                signalRepository.findByStock_SymbolIgnoreCaseOrderBySignalDateDesc(symbol));
    }
}
