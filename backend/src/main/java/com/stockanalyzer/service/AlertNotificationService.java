package com.stockanalyzer.service;

import com.stockanalyzer.entity.Alert;
import com.stockanalyzer.entity.Signal;
import com.stockanalyzer.entity.StockPrice;
import com.stockanalyzer.entity.TechnicalIndicator;
import com.stockanalyzer.repository.AlertRepository;
import com.stockanalyzer.repository.SignalRepository;
import com.stockanalyzer.repository.StockPriceRepository;
import com.stockanalyzer.repository.TechnicalIndicatorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;

/**
 * Evaluates each active user alert against the latest market data
 * and fires email notifications when thresholds are hit.
 *
 * Called from the daily scheduler after indicators are ready.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class AlertNotificationService {

    private static final BigDecimal VOLUME_MULTIPLIER = new BigDecimal("1.5");
    private static final BigDecimal RSI_OVERBOUGHT    = new BigDecimal("70");
    private static final BigDecimal RSI_OVERSOLD      = new BigDecimal("35");

    private final AlertRepository             alertRepository;
    private final StockPriceRepository        priceRepository;
    private final TechnicalIndicatorRepository indicatorRepository;
    private final SignalRepository            signalRepository;
    private final EmailService                emailService;

    // ─── Public API ───────────────────────────────────────────────────────────

    @Transactional
    public void processAllAlerts() {
        List<Alert> activeAlerts = alertRepository.findByActiveTrueOrderByStock_SymbolAsc();
        log.info("Processing {} active alerts", activeAlerts.size());

        int fired = 0;
        for (Alert alert : activeAlerts) {
            try {
                if (evaluateAndFire(alert)) fired++;
            } catch (Exception e) {
                log.error("Error processing alert id={}: {}", alert.getId(), e.getMessage());
            }
        }
        log.info("Alert processing complete — {} alerts fired", fired);
    }

    // ─── Evaluation logic ─────────────────────────────────────────────────────

    private boolean evaluateAndFire(Alert alert) {
        var priceOpt = priceRepository.findLatestByStockId(alert.getStock().getId());
        var indOpt   = indicatorRepository.findLatestByStockId(alert.getStock().getId());

        if (priceOpt.isEmpty()) return false;

        StockPrice         price     = priceOpt.get();
        TechnicalIndicator indicator = indOpt.orElse(null);
        BigDecimal         close     = price.getClosePrice();

        boolean triggered = switch (alert.getAlertType()) {
            case PRICE_ABOVE         -> close != null && alert.getThreshold() != null
                                        && close.compareTo(alert.getThreshold()) > 0;
            case PRICE_BELOW         -> close != null && alert.getThreshold() != null
                                        && close.compareTo(alert.getThreshold()) < 0;
            case MA220_CROSSOVER_UP  -> indicator != null && close != null
                                        && indicator.getMa220() != null
                                        && close.compareTo(indicator.getMa220()) > 0;
            case MA220_CROSSOVER_DOWN -> indicator != null && close != null
                                        && indicator.getMa220() != null
                                        && close.compareTo(indicator.getMa220()) < 0;
            case MA50_CROSSOVER_UP   -> indicator != null && close != null
                                        && indicator.getMa50() != null
                                        && close.compareTo(indicator.getMa50()) > 0;
            case MA50_CROSSOVER_DOWN -> indicator != null && close != null
                                        && indicator.getMa50() != null
                                        && close.compareTo(indicator.getMa50()) < 0;
            case RSI_OVERBOUGHT      -> indicator != null && indicator.getRsi14() != null
                                        && indicator.getRsi14().compareTo(RSI_OVERBOUGHT) > 0;
            case RSI_OVERSOLD        -> indicator != null && indicator.getRsi14() != null
                                        && indicator.getRsi14().compareTo(RSI_OVERSOLD) < 0;
            case VOLUME_BREAKOUT     -> indicator != null && price.getVolume() != null
                                        && indicator.getVolumeAvg20() != null
                                        && new BigDecimal(price.getVolume())
                                            .compareTo(new BigDecimal(indicator.getVolumeAvg20())
                                                .multiply(VOLUME_MULTIPLIER)) >= 0;
            case WEEK_52_HIGH        -> indicator != null && close != null
                                        && indicator.getWeek52High() != null
                                        && close.compareTo(
                                            indicator.getWeek52High()
                                                .multiply(new BigDecimal("0.98"))) >= 0;
        };

        if (!triggered) return false;

        // Avoid spamming — don't re-fire if already triggered today
        if (alert.getLastTriggered() != null
                && alert.getLastTriggered().toLocalDate().equals(LocalDate.now())) {
            return false;
        }

        // Build a synthetic Signal for the email template
        Signal.SignalType type = isSelSignal(alert.getAlertType())
                ? Signal.SignalType.SELL : Signal.SignalType.BUY;

        Signal syntheticSignal = Signal.builder()
                .stock(alert.getStock())
                .signalDate(price.getTradeDate())
                .signalType(type)
                .strategy(alert.getAlertType().name())
                .triggerPrice(close)
                .notes(buildNote(alert, close, indicator))
                .build();

        emailService.sendAlertNotification(alert.getUser(), syntheticSignal,
                syntheticSignal.getNotes());

        // Update last triggered timestamp
        alert.setLastTriggered(LocalDateTime.now());
        alertRepository.save(alert);

        log.info("Alert fired: user={} stock={} type={}",
                alert.getUser().getEmail(), alert.getStock().getSymbol(), alert.getAlertType());
        return true;
    }

    private boolean isSelSignal(Alert.AlertType type) {
        return type == Alert.AlertType.PRICE_BELOW
            || type == Alert.AlertType.MA220_CROSSOVER_DOWN
            || type == Alert.AlertType.MA50_CROSSOVER_DOWN
            || type == Alert.AlertType.RSI_OVERBOUGHT;
    }

    private String buildNote(Alert alert, BigDecimal close, TechnicalIndicator ind) {
        return switch (alert.getAlertType()) {
            case PRICE_ABOVE  -> "Price ₹" + close + " crossed above threshold ₹" + alert.getThreshold();
            case PRICE_BELOW  -> "Price ₹" + close + " dropped below threshold ₹" + alert.getThreshold();
            case MA220_CROSSOVER_UP   -> "Price ₹" + close + " crossed above 220-DMA ₹" + (ind != null ? ind.getMa220() : "—");
            case MA220_CROSSOVER_DOWN -> "Price ₹" + close + " crossed below 220-DMA ₹" + (ind != null ? ind.getMa220() : "—");
            case MA50_CROSSOVER_UP    -> "Price ₹" + close + " crossed above 50-DMA ₹" + (ind != null ? ind.getMa50() : "—");
            case MA50_CROSSOVER_DOWN  -> "Price ₹" + close + " crossed below 50-DMA ₹" + (ind != null ? ind.getMa50() : "—");
            case RSI_OVERBOUGHT -> "RSI=" + (ind != null ? ind.getRsi14() : "—") + " — overbought";
            case RSI_OVERSOLD   -> "RSI=" + (ind != null ? ind.getRsi14() : "—") + " — oversold";
            case VOLUME_BREAKOUT -> "Volume spike detected";
            case WEEK_52_HIGH    -> "Price near 52-week high — breakout signal";
        };
    }
}
