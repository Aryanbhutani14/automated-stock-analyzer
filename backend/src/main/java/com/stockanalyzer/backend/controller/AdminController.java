package com.stockanalyzer.backend.controller;

import com.stockanalyzer.backend.dto.MessageResponse;
import com.stockanalyzer.backend.scheduler.StockDataScheduler;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.concurrent.CompletableFuture;

@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private static final Logger logger = LoggerFactory.getLogger(AdminController.class);

    @Autowired
    private StockDataScheduler scheduler;

    @PostMapping("/trigger-pipeline")
    @PreAuthorize("hasRole('ADMIN')")
    public ResponseEntity<MessageResponse> triggerPipeline() {
        logger.info("Manual pipeline trigger initiated by admin.");
        
        // Execute the daily pipeline asynchronously so the HTTP response isn't held open
        CompletableFuture.runAsync(() -> {
            try {
                scheduler.triggerManually();
            } catch (Exception e) {
                logger.error("Error running manual pipeline: {}", e.getMessage(), e);
            }
        });

        return ResponseEntity.ok(new MessageResponse("Pipeline triggered successfully - running in background."));
    }
}
