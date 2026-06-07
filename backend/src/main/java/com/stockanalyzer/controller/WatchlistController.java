package com.stockanalyzer.controller;

import com.stockanalyzer.dto.AddStockRequest;
import com.stockanalyzer.dto.ApiResponse;
import com.stockanalyzer.dto.CreateWatchlistRequest;
import com.stockanalyzer.dto.WatchlistDto;
import com.stockanalyzer.service.WatchlistService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * GET    /api/watchlists
 * POST   /api/watchlists
 * DELETE /api/watchlists/{id}
 * POST   /api/watchlists/{id}/stocks
 * DELETE /api/watchlists/{id}/stocks/{symbol}
 */
@RestController
@RequestMapping("/api/watchlists")
@RequiredArgsConstructor
public class WatchlistController {

    private final WatchlistService watchlistService;

    @GetMapping
    public ResponseEntity<List<WatchlistDto>> getAll(
            @AuthenticationPrincipal UserDetails user) {
        return ResponseEntity.ok(watchlistService.getUserWatchlists(user.getUsername()));
    }

    @PostMapping
    public ResponseEntity<WatchlistDto> create(
            @AuthenticationPrincipal UserDetails user,
            @Valid @RequestBody CreateWatchlistRequest req) {
        WatchlistDto created = watchlistService.createWatchlist(
                user.getUsername(), req.getName(), req.getDescription());
        return ResponseEntity.status(HttpStatus.CREATED).body(created);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<ApiResponse> delete(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id) {
        watchlistService.deleteWatchlist(user.getUsername(), id);
        return ResponseEntity.ok(ApiResponse.ok("Watchlist deleted"));
    }

    @PostMapping("/{id}/stocks")
    public ResponseEntity<WatchlistDto> addStock(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id,
            @Valid @RequestBody AddStockRequest req) {
        return ResponseEntity.ok(watchlistService.addStock(user.getUsername(), id, req.getSymbol()));
    }

    @DeleteMapping("/{id}/stocks/{symbol}")
    public ResponseEntity<WatchlistDto> removeStock(
            @AuthenticationPrincipal UserDetails user,
            @PathVariable Long id,
            @PathVariable String symbol) {
        return ResponseEntity.ok(watchlistService.removeStock(user.getUsername(), id, symbol));
    }
}
