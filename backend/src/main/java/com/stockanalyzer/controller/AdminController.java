package com.stockanalyzer.controller;

import com.stockanalyzer.dto.ApiResponse;
import com.stockanalyzer.scheduler.StockDataScheduler;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Admin-only endpoints.
 * Requires ROLE_ADMIN (enforced via @PreAuthorize).
 *
 * POST /api/admin/trigger-pipeline  — manually run the daily data pipeline
 */
@Slf4j
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final StockDataScheduler scheduler;

    @PostMapping("/trigger-pipeline")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<ApiResponse> triggerPipeline() {
        log.info("Manual pipeline trigger by admin");
        // Run async so the HTTP response isn't held open for the full pipeline duration
        Thread.ofVirtual().start(scheduler::triggerManually);
        return ResponseEntity.ok(ApiResponse.ok("Pipeline triggered — running in background"));
    }
}
