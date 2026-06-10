package com.stockanalyzer.backend.controller;

import com.stockanalyzer.backend.dto.AlertDto;
import com.stockanalyzer.backend.dto.CreateAlertRequest;
import com.stockanalyzer.backend.dto.MessageResponse;
import com.stockanalyzer.backend.service.AlertService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/alerts")
public class AlertController {

    @Autowired
    private AlertService alertService;

    @GetMapping
    public ResponseEntity<List<AlertDto>> getAlerts(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(alertService.getAlertsForUser(principal.getName()));
    }

    @PostMapping
    public ResponseEntity<?> createAlert(Principal principal, @Valid @RequestBody CreateAlertRequest request) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            AlertDto alert = alertService.createAlert(principal.getName(), request);
            return ResponseEntity.status(HttpStatus.CREATED).body(alert);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteAlert(Principal principal, @PathVariable Long id) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            alertService.deleteAlert(principal.getName(), id);
            return ResponseEntity.ok(new MessageResponse("Alert deleted successfully."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(new MessageResponse(e.getMessage()));
        }
    }
}
