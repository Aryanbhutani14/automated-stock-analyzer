package com.stockanalyzer.controller;

import com.stockanalyzer.dto.ScreenerResultDto;
import com.stockanalyzer.service.ScreenerService;
import com.stockanalyzer.service.ScreenerService.ScreenerFilter;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * REST endpoints for the stock screener.
 *
 * GET /api/screener?filter=MA220_CROSSOVER&exchange=NSE&sector=Technology
 * GET /api/screener/all?exchange=NSE
 * GET /api/screener/filters  — list available filter names
 */
@RestController
@RequestMapping("/api/screener")
@RequiredArgsConstructor
public class ScreenerController {

    private final ScreenerService screenerService;

    @GetMapping
    public ResponseEntity<List<ScreenerResultDto>> screen(
            @RequestParam(defaultValue = "ALL") String filter,
            @RequestParam(required = false)     String exchange,
            @RequestParam(required = false)     String sector) {

        ScreenerFilter f = ScreenerFilter.valueOf(filter.toUpperCase());
        return ResponseEntity.ok(screenerService.screen(f, exchange, sector));
    }

    @GetMapping("/all")
    public ResponseEntity<List<ScreenerResultDto>> screenAll(
            @RequestParam(required = false) String exchange,
            @RequestParam(required = false) String sector) {
        return ResponseEntity.ok(screenerService.screenAll(exchange, sector));
    }

    @GetMapping("/filters")
    public ResponseEntity<ScreenerFilter[]> getFilters() {
        return ResponseEntity.ok(ScreenerFilter.values());
    }
}
