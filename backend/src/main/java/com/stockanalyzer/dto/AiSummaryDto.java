package com.stockanalyzer.dto;

import com.stockanalyzer.entity.AiSummary;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDate;

@Data
@Builder
public class AiSummaryDto {

    private String    symbol;
    private String    stockName;
    private LocalDate date;
    private String    summary;
    private String    modelUsed;

    public static AiSummaryDto from(AiSummary s) {
        return AiSummaryDto.builder()
                .symbol(s.getStock().getSymbol())
                .stockName(s.getStock().getName())
                .date(s.getSummaryDate())
                .summary(s.getSummaryText())
                .modelUsed(s.getModelUsed())
                .build();
    }
}
