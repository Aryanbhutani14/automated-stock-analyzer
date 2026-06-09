package com.stockanalyzer.backend.controller;

import com.stockanalyzer.backend.dto.MessageResponse;
import com.stockanalyzer.backend.dto.StockDetailDto;
import com.stockanalyzer.backend.dto.StockDto;
import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import com.stockanalyzer.backend.repository.StockPriceRepository;
import com.stockanalyzer.backend.repository.StockRepository;
import com.stockanalyzer.backend.service.YahooFinanceService;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@RestController
@RequestMapping("/api/stocks")
public class StockController {

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private StockPriceRepository stockPriceRepository;

    @Autowired
    private YahooFinanceService yahooFinanceService;

    @GetMapping
    public ResponseEntity<List<StockDto>> getAllStocks() {
        List<Stock> stocks = stockRepository.findAll().stream()
                .filter(Stock::getIsActive)
                .toList();

        List<StockDto> stockDtos = stocks.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());

        return ResponseEntity.ok(stockDtos);
    }

    @GetMapping("/{symbol}")
    public ResponseEntity<StockDetailDto> getStockDetails(@PathVariable String symbol) {
        return stockRepository.findBySymbol(symbol)
                .map(stock -> {
                    StockDto stockDto = convertToDto(stock);
                    List<StockPrice> priceHistory = stockPriceRepository.findByStockOrderByTradeDateAsc(stock);
                    
                    List<StockDetailDto.PricePoint> points = priceHistory.stream()
                            .map(price -> new StockDetailDto.PricePoint(
                                    price.getTradeDate(),
                                    price.getOpenPrice(),
                                    price.getHighPrice(),
                                    price.getLowPrice(),
                                    price.getClosePrice(),
                                    price.getVolume()
                            ))
                            .collect(Collectors.toList());

                    return ResponseEntity.ok(new StockDetailDto(stockDto, points));
                })
                .orElse(ResponseEntity.notFound().build());
    }

    @PostMapping("/sync")
    public ResponseEntity<?> syncStocks() {
        CompletableFuture.runAsync(() -> {
            try {
                yahooFinanceService.syncAllActiveStocks();
            } catch (Exception e) {
                // Logged automatically inside service
            }
        });
        return ResponseEntity.ok(new MessageResponse("Stock synchronization triggered successfully."));
    }

    private StockDto convertToDto(Stock stock) {
        List<StockPrice> latestPrices = stockPriceRepository.findTop2ByStockOrderByTradeDateDesc(stock);
        Double price = null;
        Double change = 0.0;
        Double changePercent = 0.0;
        Long volume = null;

        if (!latestPrices.isEmpty()) {
            StockPrice latest = latestPrices.get(0);
            price = latest.getClosePrice();
            volume = latest.getVolume();

            if (latestPrices.size() > 1) {
                StockPrice prev = latestPrices.get(1);
                if (price != null && prev.getClosePrice() != null) {
                    change = price - prev.getClosePrice();
                    if (prev.getClosePrice() != 0) {
                        changePercent = (change / prev.getClosePrice()) * 100;
                    }
                }
            }
        }

        return new StockDto(
                stock.getId(),
                stock.getSymbol(),
                stock.getName(),
                stock.getExchange(),
                stock.getSector(),
                stock.getIndustry(),
                price,
                change,
                changePercent,
                volume
        );
    }
}
