package com.stockanalyzer.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.scheduling.annotation.EnableAsync;

/**
 * Enables Spring's @Async support.
 * Used by EmailService to send emails without blocking the pipeline thread.
 */
@Configuration
@EnableAsync
public class AsyncConfig {
    // Spring Boot's default thread pool is sufficient for our email volume.
    // Customise here if high throughput is needed.
}
