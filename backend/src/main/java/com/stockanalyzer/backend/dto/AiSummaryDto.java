package com.stockanalyzer.backend.dto;

import java.time.LocalDate;

public class AiSummaryDto {
    private String symbol;
    private String summaryText;
    private LocalDate summaryDate;
    private String modelUsed;

    public AiSummaryDto() {}

    public AiSummaryDto(String symbol, String summaryText, LocalDate summaryDate, String modelUsed) {
        this.symbol = symbol;
        this.summaryText = summaryText;
        this.summaryDate = summaryDate;
        this.modelUsed = modelUsed;
    }

    public String getSymbol() { return symbol; }
    public void setSymbol(String symbol) { this.symbol = symbol; }

    public String getSummaryText() { return summaryText; }
    public void setSummaryText(String summaryText) { this.summaryText = summaryText; }

    public LocalDate getSummaryDate() { return summaryDate; }
    public void setSummaryDate(LocalDate summaryDate) { this.summaryDate = summaryDate; }

    public String getModelUsed() { return modelUsed; }
    public void setModelUsed(String modelUsed) { this.modelUsed = modelUsed; }
}
