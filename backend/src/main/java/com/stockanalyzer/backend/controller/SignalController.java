package com.stockanalyzer.backend.controller;

import com.stockanalyzer.backend.model.Signal;
import com.stockanalyzer.backend.model.Signal.SignalType;
import com.stockanalyzer.backend.repository.SignalRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/api/signals")
public class SignalController {

    @Autowired
    private SignalRepository signalRepository;

    @GetMapping
    public ResponseEntity<List<Signal>> getSignalsByDate(
            @RequestParam(required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate date,
            @RequestParam(required = false) String type) {

        LocalDate targetDate = date != null ? date : LocalDate.now();

        if (type != null && !type.trim().isEmpty()) {
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
