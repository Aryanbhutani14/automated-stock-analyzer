package com.stockanalyzer.backend.service;

import com.stockanalyzer.backend.model.Alert;
import com.stockanalyzer.backend.model.AlertType;
import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import com.stockanalyzer.backend.model.TechnicalIndicator;
import com.stockanalyzer.backend.repository.AlertRepository;
import com.stockanalyzer.backend.repository.StockPriceRepository;
import com.stockanalyzer.backend.repository.TechnicalIndicatorRepository;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

@Service
@Transactional
public class AlertNotificationService {

    private static final Logger logger = LoggerFactory.getLogger(AlertNotificationService.class);

    @Autowired
    private AlertRepository alertRepository;

    @Autowired
    private StockPriceRepository stockPriceRepository;

    @Autowired
    private TechnicalIndicatorRepository indicatorRepository;

    @Autowired
    private EmailService emailService;

    public void processAllAlerts() {
        List<Alert> activeAlerts = alertRepository.findByActiveTrueOrderByStock_SymbolAsc();
        logger.info("Processing {} active alerts...", activeAlerts.size());

        for (Alert alert : activeAlerts) {
            try {
                // Prevent duplicate alarms on the same day
                if (alert.getLastTriggered() != null && alert.getLastTriggered().toLocalDate().equals(LocalDate.now())) {
                    continue;
                }

                evaluateAlert(alert);
            } catch (Exception e) {
                logger.error("Failed to process alert ID {}: {}", alert.getId(), e.getMessage());
            }
        }
        logger.info("Alert processing complete.");
    }

    private void evaluateAlert(Alert alert) {
        Stock stock = alert.getStock();
        List<StockPrice> priceHistory = stockPriceRepository.findLatestNByStockId(stock.getId(), 2);
        if (priceHistory.isEmpty()) return;

        StockPrice todayPrice = priceHistory.get(0);
        Double todayClose = todayPrice.getClosePrice();
        Double prevClose = priceHistory.size() > 1 ? priceHistory.get(1).getClosePrice() : null;

        List<TechnicalIndicator> indicators = indicatorRepository.findTop2ByStockIdOrderByTradeDateDesc(stock.getId());
        TechnicalIndicator todayInd = !indicators.isEmpty() ? indicators.get(0) : null;
        TechnicalIndicator prevInd = indicators.size() > 1 ? indicators.get(1) : null;

        boolean triggered = false;
        AlertType type = alert.getAlertType();
        Double threshold = alert.getThreshold();

        switch (type) {
            case PRICE_ABOVE:
                if (todayClose != null && threshold != null && todayClose > threshold) {
                    triggered = true;
                }
                break;
            case PRICE_BELOW:
                if (todayClose != null && threshold != null && todayClose < threshold) {
                    triggered = true;
                }
                break;
            case MA50_CROSSOVER_UP:
                if (todayClose != null && todayInd != null && todayInd.getMa50() != null) {
                    boolean todayAbove = todayClose > todayInd.getMa50();
                    boolean prevAbove = prevClose != null && prevInd != null && prevInd.getMa50() != null && prevClose > prevInd.getMa50();
                    if (todayAbove && !prevAbove) triggered = true;
                }
                break;
            case MA50_CROSSOVER_DOWN:
                if (todayClose != null && todayInd != null && todayInd.getMa50() != null) {
                    boolean todayBelow = todayClose < todayInd.getMa50();
                    boolean prevBelow = prevClose != null && prevInd != null && prevInd.getMa50() != null && prevClose < prevInd.getMa50();
                    if (todayBelow && !prevBelow) triggered = true;
                }
                break;
            case MA220_CROSSOVER_UP:
                if (todayClose != null && todayInd != null && todayInd.getMa220() != null) {
                    boolean todayAbove = todayClose > todayInd.getMa220();
                    boolean prevAbove = prevClose != null && prevInd != null && prevInd.getMa220() != null && prevClose > prevInd.getMa220();
                    if (todayAbove && !prevAbove) triggered = true;
                }
                break;
            case MA220_CROSSOVER_DOWN:
                if (todayClose != null && todayInd != null && todayInd.getMa220() != null) {
                    boolean todayBelow = todayClose < todayInd.getMa220();
                    boolean prevBelow = prevClose != null && prevInd != null && prevInd.getMa220() != null && prevClose < prevInd.getMa220();
                    if (todayBelow && !prevBelow) triggered = true;
                }
                break;
            case RSI_OVERBOUGHT:
                if (todayInd != null && todayInd.getRsi14() != null) {
                    double limit = threshold != null ? threshold : 70.0;
                    if (todayInd.getRsi14() >= limit) triggered = true;
                }
                break;
            case RSI_OVERSOLD:
                if (todayInd != null && todayInd.getRsi14() != null) {
                    double limit = threshold != null ? threshold : 35.0;
                    if (todayInd.getRsi14() <= limit) triggered = true;
                }
                break;
            case VOLUME_BREAKOUT:
                if (todayPrice.getVolume() != null && todayInd != null && todayInd.getVolumeAvg20() != null && todayInd.getVolumeAvg20() > 0) {
                    double factor = threshold != null ? threshold : 1.5;
                    if (todayPrice.getVolume() >= todayInd.getVolumeAvg20() * factor) triggered = true;
                }
                break;
            case WEEK_52_HIGH:
                if (todayClose != null && todayInd != null && todayInd.getWeek52High() != null && todayInd.getWeek52High() > 0) {
                    double factor = threshold != null ? threshold : 0.98;
                    if (todayClose >= todayInd.getWeek52High() * factor) triggered = true;
                }
                break;
        }

        if (triggered) {
            alert.setLastTriggered(LocalDateTime.now());
            alertRepository.save(alert);

            String userEmail = alert.getUser().getEmail();
            String username = alert.getUser().getUsername();
            String subject = "ALERT TRIGGERED: " + stock.getSymbol() + " - " + type.name();
            String body = emailService.buildAlertEmailTemplate(username, stock.getSymbol(), stock.getName(), type.name(), todayClose, threshold);

            emailService.sendEmail(userEmail, subject, body);
            logger.info("Alert triggered and notification queued for user {} (stock: {}, alert: {})", username, stock.getSymbol(), type.name());
        }
    }
}
