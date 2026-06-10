package com.stockanalyzer.backend.service;

import com.stockanalyzer.backend.dto.AlertDto;
import com.stockanalyzer.backend.dto.CreateAlertRequest;
import com.stockanalyzer.backend.model.Alert;
import com.stockanalyzer.backend.model.AlertType;
import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.User;
import com.stockanalyzer.backend.repository.AlertRepository;
import com.stockanalyzer.backend.repository.StockRepository;
import com.stockanalyzer.backend.repository.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class AlertService {

    @Autowired
    private AlertRepository alertRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StockRepository stockRepository;

    public List<AlertDto> getAlertsForUser(String username) {
        List<Alert> alerts = alertRepository.findByUser_UsernameOrderByStock_SymbolAsc(username);
        return alerts.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public AlertDto createAlert(String username, CreateAlertRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));

        Stock stock = stockRepository.findBySymbolIgnoreCase(request.getSymbol())
                .orElseThrow(() -> new IllegalArgumentException("Stock not found with symbol: " + request.getSymbol()));

        AlertType alertType;
        try {
            alertType = AlertType.valueOf(request.getAlertType().toUpperCase());
        } catch (IllegalArgumentException e) {
            throw new IllegalArgumentException("Invalid AlertType: " + request.getAlertType());
        }

        Alert alert = new Alert(user, stock, alertType, request.getThreshold());
        alert = alertRepository.save(alert);
        return convertToDto(alert);
    }

    public void deleteAlert(String username, Long alertId) {
        Alert alert = alertRepository.findByIdAndUser_Username(alertId, username)
                .orElseThrow(() -> new IllegalArgumentException("Alert not found or unauthorized"));
        alertRepository.delete(alert);
    }

    public AlertDto convertToDto(Alert alert) {
        return new AlertDto(
                alert.getId(),
                alert.getStock().getSymbol(),
                alert.getStock().getName(),
                alert.getAlertType().name(),
                alert.getThreshold(),
                alert.isActive(),
                alert.getLastTriggered(),
                alert.getCreatedAt()
        );
    }
}
