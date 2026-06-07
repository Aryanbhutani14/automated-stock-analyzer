package com.stockanalyzer.service;

import com.stockanalyzer.dto.AlertDto;
import com.stockanalyzer.dto.CreateAlertRequest;
import com.stockanalyzer.entity.Alert;
import com.stockanalyzer.entity.Stock;
import com.stockanalyzer.entity.User;
import com.stockanalyzer.repository.AlertRepository;
import com.stockanalyzer.repository.StockRepository;
import com.stockanalyzer.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class AlertService {

    private final AlertRepository  alertRepository;
    private final UserRepository   userRepository;
    private final StockRepository  stockRepository;

    @Transactional(readOnly = true)
    public List<AlertDto> getUserAlerts(String email) {
        User user = getUser(email);
        return alertRepository.findByUser_IdAndActiveTrueOrderByCreatedAtDesc(user.getId())
                .stream().map(AlertDto::from).toList();
    }

    @Transactional
    public AlertDto createAlert(String email, CreateAlertRequest req) {
        User user = getUser(email);
        Stock stock = stockRepository.findBySymbolIgnoreCase(req.getSymbol())
                .orElseThrow(() -> new IllegalArgumentException("Stock not found: " + req.getSymbol()));

        Alert alert = Alert.builder()
                .user(user)
                .stock(stock)
                .alertType(Alert.AlertType.valueOf(req.getAlertType().toUpperCase()))
                .threshold(req.getThreshold())
                .active(true)
                .build();

        return AlertDto.from(alertRepository.save(alert));
    }

    @Transactional
    public void deleteAlert(String email, Long alertId) {
        User user = getUser(email);
        Alert alert = alertRepository.findByIdAndUser_Id(alertId, user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Alert not found or access denied"));
        // Soft-delete: mark inactive instead of removing
        alert.setActive(false);
        alertRepository.save(alert);
    }

    private User getUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));
    }
}
