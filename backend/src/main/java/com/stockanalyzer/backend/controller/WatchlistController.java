package com.stockanalyzer.backend.controller;

import com.stockanalyzer.backend.dto.AddStockRequest;
import com.stockanalyzer.backend.dto.CreateWatchlistRequest;
import com.stockanalyzer.backend.dto.MessageResponse;
import com.stockanalyzer.backend.dto.WatchlistDto;
import com.stockanalyzer.backend.service.WatchlistService;
import jakarta.validation.Valid;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;
import java.security.Principal;
import java.util.List;

@RestController
@RequestMapping("/api/watchlists")
public class WatchlistController {

    @Autowired
    private WatchlistService watchlistService;

    @GetMapping
    public ResponseEntity<List<WatchlistDto>> getWatchlists(Principal principal) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        return ResponseEntity.ok(watchlistService.getWatchlistsForUser(principal.getName()));
    }

    @PostMapping
    public ResponseEntity<WatchlistDto> createWatchlist(Principal principal, @Valid @RequestBody CreateWatchlistRequest request) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        WatchlistDto watchlist = watchlistService.createWatchlist(principal.getName(), request);
        return ResponseEntity.status(HttpStatus.CREATED).body(watchlist);
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<?> deleteWatchlist(Principal principal, @PathVariable Long id) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            watchlistService.deleteWatchlist(principal.getName(), id);
            return ResponseEntity.ok(new MessageResponse("Watchlist deleted successfully."));
        } catch (IllegalArgumentException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body(new MessageResponse(e.getMessage()));
        }
    }

    @PostMapping("/{id}/stocks")
    public ResponseEntity<?> addStockToWatchlist(Principal principal, @PathVariable Long id, @Valid @RequestBody AddStockRequest request) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            WatchlistDto updated = watchlistService.addStockToWatchlist(principal.getName(), id, request.getSymbol());
            return ResponseEntity.ok(updated);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }

    @DeleteMapping("/{id}/stocks/{symbol}")
    public ResponseEntity<?> removeStockFromWatchlist(Principal principal, @PathVariable Long id, @PathVariable String symbol) {
        if (principal == null) {
            return ResponseEntity.status(HttpStatus.UNAUTHORIZED).build();
        }
        try {
            WatchlistDto updated = watchlistService.removeStockFromWatchlist(principal.getName(), id, symbol);
            return ResponseEntity.ok(updated);
        } catch (IllegalArgumentException e) {
            return ResponseEntity.badRequest().body(new MessageResponse(e.getMessage()));
        }
    }
}
