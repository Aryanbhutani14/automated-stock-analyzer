package com.stockanalyzer.dto;

import com.stockanalyzer.entity.Watchlist;
import lombok.Builder;
import lombok.Data;

import java.time.LocalDateTime;
import java.util.List;

@Data
@Builder
public class WatchlistDto {

    private Long   id;
    private String name;
    private String description;
    private List<String> symbols;   // stock symbols in this watchlist
    private LocalDateTime createdAt;

    public static WatchlistDto from(Watchlist wl) {
        return WatchlistDto.builder()
                .id(wl.getId())
                .name(wl.getName())
                .description(wl.getDescription())
                .symbols(wl.getStocks().stream()
                           .map(s -> s.getSymbol()).toList())
                .createdAt(wl.getCreatedAt())
                .build();
    }
}
