package com.stockanalyzer;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
public class AutomatedStockAnalyzerApplication {

    public static void main(String[] args) {
        SpringApplication.run(AutomatedStockAnalyzerApplication.class, args);
    }
}
