package com.stockanalyzer.service;

import com.stockanalyzer.dto.WatchlistDto;
import com.stockanalyzer.entity.Stock;
import com.stockanalyzer.entity.User;
import com.stockanalyzer.entity.Watchlist;
import com.stockanalyzer.repository.StockRepository;
import com.stockanalyzer.repository.UserRepository;
import com.stockanalyzer.repository.WatchlistRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

@Service
@RequiredArgsConstructor
public class WatchlistService {

    private final WatchlistRepository watchlistRepository;
    private final UserRepository      userRepository;
    private final StockRepository     stockRepository;

    @Transactional(readOnly = true)
    public List<WatchlistDto> getUserWatchlists(String email) {
        User user = getUser(email);
        return watchlistRepository.findByUser_IdOrderByCreatedAtDesc(user.getId())
                .stream().map(WatchlistDto::from).toList();
    }

    @Transactional
    public WatchlistDto createWatchlist(String email, String name, String description) {
        User user = getUser(email);
        Watchlist wl = Watchlist.builder()
                .user(user)
                .name(name)
                .description(description)
                .build();
        return WatchlistDto.from(watchlistRepository.save(wl));
    }

    @Transactional
    public WatchlistDto addStock(String email, Long watchlistId, String symbol) {
        Watchlist wl = getOwnedWatchlist(email, watchlistId);
        Stock stock = stockRepository.findBySymbolIgnoreCase(symbol)
                .orElseThrow(() -> new IllegalArgumentException("Stock not found: " + symbol));

        boolean alreadyIn = wl.getStocks().stream()
                .anyMatch(s -> s.getSymbol().equalsIgnoreCase(symbol));
        if (alreadyIn) throw new IllegalArgumentException(symbol + " is already in this watchlist");

        wl.getStocks().add(stock);
        return WatchlistDto.from(watchlistRepository.save(wl));
    }

    @Transactional
    public WatchlistDto removeStock(String email, Long watchlistId, String symbol) {
        Watchlist wl = getOwnedWatchlist(email, watchlistId);
        wl.getStocks().removeIf(s -> s.getSymbol().equalsIgnoreCase(symbol));
        return WatchlistDto.from(watchlistRepository.save(wl));
    }

    @Transactional
    public void deleteWatchlist(String email, Long watchlistId) {
        Watchlist wl = getOwnedWatchlist(email, watchlistId);
        watchlistRepository.delete(wl);
    }

    // ─── Helpers ──────────────────────────────────────────────────────────────

    private User getUser(String email) {
        return userRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException("User not found: " + email));
    }

    private Watchlist getOwnedWatchlist(String email, Long watchlistId) {
        User user = getUser(email);
        return watchlistRepository.findByIdAndUser_Id(watchlistId, user.getId())
                .orElseThrow(() -> new IllegalArgumentException("Watchlist not found or access denied"));
    }
}
