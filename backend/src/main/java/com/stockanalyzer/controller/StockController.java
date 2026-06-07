package com.stockanalyzer.controller;

import com.stockanalyzer.dto.StockDetailDto;
import com.stockanalyzer.dto.StockPriceDto;
import com.stockanalyzer.entity.Stock;
import com.stockanalyzer.entity.StockPrice;
import com.stockanalyzer.repository.StockPriceRepository;
import com.stockanalyzer.repository.StockRepository;
import com.stockanalyzer.repository.TechnicalIndicatorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

/**
 * REST endpoints for stock data.
 *
 * GET /api/stocks                        — all active stocks with latest price + indicators
 * GET /api/stocks/{symbol}               — single stock detail
 * GET /api/stocks/{symbol}/price-history — OHLCV history between two dates
 * GET /api/stocks/sectors                — list of available sectors
 */
@RestController
@RequestMapping("/api/stocks")
@RequiredArgsConstructor
public class StockController {

    private final StockRepository              stockRepository;
    private final StockPriceRepository         priceRepository;
    private final TechnicalIndicatorRepository indicatorRepository;

    @GetMapping
    public ResponseEntity<List<StockDetailDto>> getAllStocks() {
        List<StockDetailDto> result = stockRepository.findByActiveTrue().stream()
                .map(this::toDetailDto)
                .toList();
        return ResponseEntity.ok(result);
    }

    @GetMapping("/{symbol}")
    public ResponseEntity<StockDetailDto> getStock(@PathVariable String symbol) {
        return stockRepository.findBySymbolIgnoreCase(symbol)
                .map(this::toDetailDto)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/{symbol}/price-history")
    public ResponseEntity<List<StockPriceDto>> getPriceHistory(
            @PathVariable String symbol,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate from,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate to) {

        return stockRepository.findBySymbolIgnoreCase(symbol)
                .map(stock -> {
                    List<StockPriceDto> prices = priceRepository
                            .findByStock_IdAndTradeDateBetweenOrderByTradeDateAsc(
                                    stock.getId(), from, to)
                            .stream()
                            .map(StockPriceDto::from)
                            .toList();
                    return ResponseEntity.ok(prices);
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @GetMapping("/sectors")
    public ResponseEntity<List<String>> getSectors() {
        return ResponseEntity.ok(stockRepository.findAllActiveSectors());
    }

    // ─── Helper ───────────────────────────────────────────────────────────────

    private StockDetailDto toDetailDto(Stock stock) {
        var price     = priceRepository.findLatestByStockId(stock.getId()).orElse(null);
        var indicator = indicatorRepository.findLatestByStockId(stock.getId()).orElse(null);
        return StockDetailDto.from(stock, price, indicator);
    }
}
