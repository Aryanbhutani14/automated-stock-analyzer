package com.stockanalyzer.backend.repository;

import com.stockanalyzer.backend.model.Watchlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface WatchlistRepository extends JpaRepository<Watchlist, Long> {
    List<Watchlist> findByUser_UsernameOrderByCreatedAtDesc(String username);
    Optional<Watchlist> findByIdAndUser_Username(Long id, String username);
}
