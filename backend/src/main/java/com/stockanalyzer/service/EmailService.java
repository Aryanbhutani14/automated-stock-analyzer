package com.stockanalyzer.service;

import com.stockanalyzer.entity.Signal;
import com.stockanalyzer.entity.User;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import java.time.format.DateTimeFormatter;
import java.util.List;

/**
 * Sends HTML email notifications for buy/sell signals and watchlist updates.
 * All sends are @Async so they never block the pipeline thread.
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class EmailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String fromAddress;

    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd MMM yyyy");

    // ─── Public API ───────────────────────────────────────────────────────────

    /**
     * Send a daily signal digest to a user listing all BUY/SELL signals for the day.
     */
    @Async
    public void sendSignalDigest(User user, List<Signal> signals) {
        if (signals == null || signals.isEmpty()) return;
        try {
            String subject = "📈 Stock Signal Digest — " + signals.get(0).getSignalDate().format(DATE_FMT);
            String body    = buildSignalDigestHtml(user.getUsername(), signals);
            send(user.getEmail(), subject, body);
            log.info("Signal digest sent to {}", user.getEmail());
        } catch (Exception e) {
            log.error("Failed to send signal digest to {}: {}", user.getEmail(), e.getMessage());
        }
    }

    /**
     * Send a single signal alert (immediate, triggered when a price threshold is hit).
     */
    @Async
    public void sendAlertNotification(User user, Signal signal, String alertNote) {
        try {
            String emoji   = signal.getSignalType() == Signal.SignalType.BUY ? "🟢" : "🔴";
            String subject = emoji + " Alert: " + signal.getStock().getSymbol()
                           + " — " + signal.getSignalType().name();
            String body    = buildAlertHtml(user.getUsername(), signal, alertNote);
            send(user.getEmail(), subject, body);
            log.info("Alert notification sent to {} for {}", user.getEmail(), signal.getStock().getSymbol());
        } catch (Exception e) {
            log.error("Failed to send alert to {}: {}", user.getEmail(), e.getMessage());
        }
    }

    /**
     * Send a welcome email on registration.
     */
    @Async
    public void sendWelcomeEmail(User user) {
        try {
            send(user.getEmail(),
                 "Welcome to Automated Stock Analyzer 🚀",
                 buildWelcomeHtml(user.getUsername()));
        } catch (Exception e) {
            log.error("Failed to send welcome email to {}: {}", user.getEmail(), e.getMessage());
        }
    }

    // ─── HTML builders ────────────────────────────────────────────────────────

    private String buildSignalDigestHtml(String username, List<Signal> signals) {
        StringBuilder sb = new StringBuilder();
        sb.append(htmlHeader("Daily Signal Digest"));
        sb.append("<body style='font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;padding:24px;'>");
        sb.append("<div style='max-width:640px;margin:auto;background:#1e293b;border-radius:12px;padding:32px;'>");
        sb.append("<h1 style='color:#60a5fa;margin-bottom:4px;'>📈 Daily Signal Digest</h1>");
        sb.append("<p style='color:#94a3b8;'>Hi ").append(username).append(", here are today's signals:</p>");

        sb.append("<table style='width:100%;border-collapse:collapse;margin-top:16px;'>");
        sb.append("<thead><tr style='background:#334155;'>");
        sb.append("<th style='padding:10px;text-align:left;color:#94a3b8;'>Symbol</th>");
        sb.append("<th style='padding:10px;text-align:left;color:#94a3b8;'>Signal</th>");
        sb.append("<th style='padding:10px;text-align:left;color:#94a3b8;'>Strategy</th>");
        sb.append("<th style='padding:10px;text-align:right;color:#94a3b8;'>Price</th>");
        sb.append("</tr></thead><tbody>");

        for (Signal s : signals) {
            String color = s.getSignalType() == Signal.SignalType.BUY ? "#22c55e" : "#ef4444";
            sb.append("<tr style='border-bottom:1px solid #334155;'>");
            sb.append("<td style='padding:10px;font-weight:bold;'>").append(s.getStock().getSymbol()).append("</td>");
            sb.append("<td style='padding:10px;color:").append(color).append(";font-weight:bold;'>")
              .append(s.getSignalType()).append("</td>");
            sb.append("<td style='padding:10px;color:#94a3b8;'>").append(s.getStrategy()).append("</td>");
            sb.append("<td style='padding:10px;text-align:right;'>₹")
              .append(s.getTriggerPrice() != null ? s.getTriggerPrice().toPlainString() : "—")
              .append("</td>");
            sb.append("</tr>");
        }

        sb.append("</tbody></table>");
        sb.append("<p style='color:#64748b;font-size:12px;margin-top:24px;'>")
          .append("This is an automated alert. Not financial advice.</p>");
        sb.append("</div></body></html>");
        return sb.toString();
    }

    private String buildAlertHtml(String username, Signal signal, String note) {
        String color = signal.getSignalType() == Signal.SignalType.BUY ? "#22c55e" : "#ef4444";
        String emoji = signal.getSignalType() == Signal.SignalType.BUY ? "🟢" : "🔴";
        return htmlHeader("Price Alert") +
               "<body style='font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;padding:24px;'>" +
               "<div style='max-width:520px;margin:auto;background:#1e293b;border-radius:12px;padding:32px;'>" +
               "<h1 style='color:" + color + ";'>" + emoji + " " + signal.getSignalType() + " Alert</h1>" +
               "<p>Hi " + username + ",</p>" +
               "<p>A <strong style='color:" + color + ";'>" + signal.getSignalType() + "</strong> signal was triggered for <strong>"
               + signal.getStock().getSymbol() + " — " + signal.getStock().getName() + "</strong></p>" +
               "<table style='width:100%;margin-top:16px;border-collapse:collapse;'>" +
               "<tr><td style='padding:8px;color:#94a3b8;'>Trigger Price</td><td style='padding:8px;'>₹"
               + (signal.getTriggerPrice() != null ? signal.getTriggerPrice().toPlainString() : "—") + "</td></tr>" +
               "<tr><td style='padding:8px;color:#94a3b8;'>Strategy</td><td style='padding:8px;'>" + signal.getStrategy() + "</td></tr>" +
               "<tr><td style='padding:8px;color:#94a3b8;'>Date</td><td style='padding:8px;'>" + signal.getSignalDate().format(DATE_FMT) + "</td></tr>" +
               "<tr><td style='padding:8px;color:#94a3b8;'>Notes</td><td style='padding:8px;'>" + note + "</td></tr>" +
               "</table>" +
               "<p style='color:#64748b;font-size:12px;margin-top:24px;'>This is an automated alert. Not financial advice.</p>" +
               "</div></body></html>";
    }

    private String buildWelcomeHtml(String username) {
        return htmlHeader("Welcome") +
               "<body style='font-family:Arial,sans-serif;background:#0f172a;color:#e2e8f0;padding:24px;'>" +
               "<div style='max-width:520px;margin:auto;background:#1e293b;border-radius:12px;padding:32px;'>" +
               "<h1 style='color:#60a5fa;'>Welcome, " + username + "! 🚀</h1>" +
               "<p>Your account on <strong>Automated Stock Analyzer</strong> is ready.</p>" +
               "<p>You can now:</p>" +
               "<ul style='color:#94a3b8;line-height:2;'>" +
               "<li>Screen stocks by technical indicators</li>" +
               "<li>Set price & crossover alerts</li>" +
               "<li>Build watchlists</li>" +
               "<li>View AI-generated stock summaries</li>" +
               "<li>Run historical backtests</li>" +
               "</ul>" +
               "<p style='color:#64748b;font-size:12px;margin-top:24px;'>Not financial advice.</p>" +
               "</div></body></html>";
    }

    private String htmlHeader(String title) {
        return "<!DOCTYPE html><html><head><meta charset='UTF-8'><title>" + title + "</title></head>";
    }

    // ─── Core send ────────────────────────────────────────────────────────────

    private void send(String to, String subject, String htmlBody) throws MessagingException {
        MimeMessage message = mailSender.createMimeMessage();
        MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
        helper.setFrom(fromAddress);
        helper.setTo(to);
        helper.setSubject(subject);
        helper.setText(htmlBody, true);
        mailSender.send(message);
    }
}
