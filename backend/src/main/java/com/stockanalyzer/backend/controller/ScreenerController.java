package com.stockanalyzer.backend.controller;

import com.stockanalyzer.backend.dto.ScreenerResultDto;
import com.stockanalyzer.backend.service.ScreenerService;
import com.stockanalyzer.backend.service.ScreenerService.ScreenerFilter;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/screener")
public class ScreenerController {

    @Autowired
    private ScreenerService screenerService;

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
