package com.stockanalyzer.backend.service;

import jakarta.mail.internet.MimeMessage;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;
import java.io.File;
import java.io.FileWriter;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.time.LocalDateTime;

@Service
public class EmailService {
    private static final Logger logger = LoggerFactory.getLogger(EmailService.class);

    @Autowired(required = false)
    private JavaMailSender mailSender;

    @Async
    public void sendEmail(String to, String subject, String htmlBody) {
        logger.info("Preparing to send email to {} with subject: {}", to, subject);
        
        boolean sent = false;
        if (mailSender != null) {
            try {
                MimeMessage message = mailSender.createMimeMessage();
                MimeMessageHelper helper = new MimeMessageHelper(message, true, "UTF-8");
                helper.setTo(to);
                helper.setSubject(subject);
                helper.setText(htmlBody, true);
                
                mailSender.send(message);
                logger.info("Email successfully sent to {}", to);
                sent = true;
            } catch (Exception e) {
                logger.warn("Failed to send email via SMTP: {}. Falling back to file logging.", e.getMessage());
            }
        } else {
            logger.info("JavaMailSender is not configured. Falling back to file logging.");
        }

        if (!sent) {
            logEmailToFile(to, subject, htmlBody);
        }
    }

    private void logEmailToFile(String to, String subject, String htmlBody) {
        String logDir = "logs";
        String logFile = logDir + "/sent_emails.log";
        try {
            Files.createDirectories(Paths.get(logDir));
            try (FileWriter writer = new FileWriter(logFile, true)) {
                writer.write("=================================================================\n");
                writer.write("TIMESTAMP: " + LocalDateTime.now() + "\n");
                writer.write("TO: " + to + "\n");
                writer.write("SUBJECT: " + subject + "\n");
                writer.write("BODY:\n" + htmlBody + "\n");
                writer.write("=================================================================\n\n");
            }
            logger.info("Logged fallback email alert to file: {}", new File(logFile).getAbsolutePath());
        } catch (IOException e) {
            logger.error("Failed to write email alert to log file: {}", e.getMessage());
        }
    }

    public String buildAlertEmailTemplate(String username, String symbol, String stockName, String condition, Double price, Double threshold) {
        return "<!DOCTYPE html>\n" +
                "<html>\n" +
                "<head>\n" +
                "  <meta charset=\"utf-8\">\n" +
                "  <title>Stock Alert Triggered</title>\n" +
                "  <style>\n" +
                "    body { font-family: 'Outfit', sans-serif; background-color: #0f172a; color: #f1f5f9; padding: 20px; margin: 0; }\n" +
                "    .card { background: rgba(30, 41, 59, 0.7); border: 1px solid rgba(255, 255, 255, 0.1); border-radius: 12px; padding: 24px; max-width: 600px; margin: 0 auto; box-shadow: 0 4px 6px rgba(0, 0, 0, 0.1); }\n" +
                "    .header { font-size: 24px; font-weight: bold; background: linear-gradient(135deg, #38bdf8, #818cf8); -webkit-background-clip: text; -webkit-text-fill-color: transparent; margin-bottom: 16px; text-align: center; }\n" +
                "    .divider { height: 1px; background: rgba(255, 255, 255, 0.1); margin: 20px 0; }\n" +
                "    .stock-box { background: rgba(15, 23, 42, 0.6); padding: 16px; border-radius: 8px; border-left: 4px solid #38bdf8; margin: 16px 0; }\n" +
                "    .stock-symbol { font-size: 20px; font-weight: 700; color: #38bdf8; }\n" +
                "    .stock-name { font-size: 14px; color: #94a3b8; }\n" +
                "    .alert-detail { font-size: 16px; margin: 12px 0; }\n" +
                "    .value { font-weight: bold; color: #38bdf8; }\n" +
                "    .footer { text-align: center; font-size: 12px; color: #64748b; margin-top: 24px; }\n" +
                "  </style>\n" +
                "</head>\n" +
                "<body>\n" +
                "  <div class=\"card\">\n" +
                "    <div class=\"header\">Automated Stock Analyzer Alert</div>\n" +
                "    <div class=\"divider\"></div>\n" +
                "    <p>Hi " + username + ",</p>\n" +
                "    <p>The following conditional stock alert you set has been triggered:</p>\n" +
                "    <div class=\"stock-box\">\n" +
                "      <div class=\"stock-symbol\">" + symbol + "</div>\n" +
                "      <div class=\"stock-name\">" + stockName + "</div>\n" +
                "    </div>\n" +
                "    <div class=\"alert-detail\">\n" +
                "      Condition: <span class=\"value\">" + condition + "</span><br/>\n" +
                "      Trigger Price: <span class=\"value\">$" + (price != null ? String.format("%.2f", price) : "N/A") + "</span><br/>\n" +
                "      Threshold Target: <span class=\"value\">" + (threshold != null ? String.format("%.2f", threshold) : "N/A") + "</span>\n" +
                "    </div>\n" +
                "    <div class=\"divider\"></div>\n" +
                "    <p>Please log into the app to inspect technical indicators and screener signals.</p>\n" +
                "    <div class=\"footer\">This is an automated notification. Please do not reply.</div>\n" +
                "  </div>\n" +
                "</body>\n" +
                "</html>";
    }
}
