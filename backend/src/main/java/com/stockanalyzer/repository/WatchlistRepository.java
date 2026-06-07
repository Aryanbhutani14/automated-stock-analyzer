package com.stockanalyzer.repository;

import com.stockanalyzer.entity.Watchlist;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface WatchlistRepository extends JpaRepository<Watchlist, Long> {

    List<Watchlist> findByUser_IdOrderByCreatedAtDesc(Long userId);

    Optional<Watchlist> findByIdAndUser_Id(Long watchlistId, Long userId);
}
