package com.stockanalyzer.backend.service;

import com.stockanalyzer.backend.dto.CreateWatchlistRequest;
import com.stockanalyzer.backend.dto.StockDto;
import com.stockanalyzer.backend.dto.WatchlistDto;
import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import com.stockanalyzer.backend.model.User;
import com.stockanalyzer.backend.model.Watchlist;
import com.stockanalyzer.backend.repository.StockPriceRepository;
import com.stockanalyzer.backend.repository.StockRepository;
import com.stockanalyzer.backend.repository.UserRepository;
import com.stockanalyzer.backend.repository.WatchlistRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import java.util.List;
import java.util.stream.Collectors;

@Service
@Transactional
public class WatchlistService {

    @Autowired
    private WatchlistRepository watchlistRepository;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private StockRepository stockRepository;

    @Autowired
    private StockPriceRepository stockPriceRepository;

    public List<WatchlistDto> getWatchlistsForUser(String username) {
        List<Watchlist> watchlists = watchlistRepository.findByUser_UsernameOrderByCreatedAtDesc(username);
        return watchlists.stream()
                .map(this::convertToDto)
                .collect(Collectors.toList());
    }

    public WatchlistDto createWatchlist(String username, CreateWatchlistRequest request) {
        User user = userRepository.findByUsername(username)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + username));
        
        Watchlist watchlist = new Watchlist(user, request.getName(), request.getDescription());
        watchlist = watchlistRepository.save(watchlist);
        return convertToDto(watchlist);
    }

    public void deleteWatchlist(String username, Long watchlistId) {
        Watchlist watchlist = watchlistRepository.findByIdAndUser_Username(watchlistId, username)
                .orElseThrow(() -> new IllegalArgumentException("Watchlist not found or unauthorized"));
        watchlistRepository.delete(watchlist);
    }

    public WatchlistDto addStockToWatchlist(String username, Long watchlistId, String symbol) {
        Watchlist watchlist = watchlistRepository.findByIdAndUser_Username(watchlistId, username)
                .orElseThrow(() -> new IllegalArgumentException("Watchlist not found or unauthorized"));

        Stock stock = stockRepository.findBySymbolIgnoreCase(symbol)
                .orElseThrow(() -> new IllegalArgumentException("Stock not found with symbol: " + symbol));

        if (!watchlist.getStocks().contains(stock)) {
            watchlist.getStocks().add(stock);
            watchlist = watchlistRepository.save(watchlist);
        }
        return convertToDto(watchlist);
    }

    public WatchlistDto removeStockFromWatchlist(String username, Long watchlistId, String symbol) {
        Watchlist watchlist = watchlistRepository.findByIdAndUser_Username(watchlistId, username)
                .orElseThrow(() -> new IllegalArgumentException("Watchlist not found or unauthorized"));

        Stock stock = stockRepository.findBySymbolIgnoreCase(symbol)
                .orElseThrow(() -> new IllegalArgumentException("Stock not found with symbol: " + symbol));

        if (watchlist.getStocks().contains(stock)) {
            watchlist.getStocks().remove(stock);
            watchlist = watchlistRepository.save(watchlist);
        }
        return convertToDto(watchlist);
    }

    private WatchlistDto convertToDto(Watchlist watchlist) {
        List<StockDto> stockDtos = watchlist.getStocks().stream()
                .map(this::convertStockToDto)
                .collect(Collectors.toList());

        return new WatchlistDto(
                watchlist.getId(),
                watchlist.getName(),
                watchlist.getDescription(),
                stockDtos,
                watchlist.getCreatedAt()
        );
    }

    private StockDto convertStockToDto(Stock stock) {
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
