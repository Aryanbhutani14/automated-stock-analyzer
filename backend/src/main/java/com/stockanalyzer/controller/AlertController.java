package com.stockanalyzer.controller;

import com.stockanalyzer.dto.AlertDto;
import com.stockanalyzer.dto.ApiResponse;
import com.stockanalyzer.dto.CreateAlertRequest;
import com.stockanalyzer.service.AlertService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * GET    /api/alerts
 * POST   /api/alerts
 * DELETE /api/alerts/{id}
 */
@RestController
@RequestMapping("/api/alerts")
@RequiredArgsConstructor
public class AlertController {

    private final AlertService alertService;

    @GetMapping
    public ResponseEntity<List<AlertDto>> getAlerts(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(alertService.getUserAlerts(user.getUsername()));
    }

    @PostMapping
    public ResponseEntity<AlertDto> createAlert(
            @AuthenticationPrincipal UserDetails user,
            @Valid @RequestBody CreateAlertRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(alertService.createAlert(user.getUsername(), req));
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> deleteAlert(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        alertService.deleteAlert(user.getUsername(), id);
        return ResponseEntity.ok(ApiResponse.ok("Alert deactivated"));
    }
}
