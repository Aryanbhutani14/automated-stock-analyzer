package com.stockanalyzer.backend.repository;

import com.stockanalyzer.backend.model.Stock;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface StockRepository extends JpaRepository<Stock, Long> {
    Optional<Stock> findBySymbol(String symbol);
    Optional<Stock> findBySymbolIgnoreCase(String symbol);
    Boolean existsBySymbol(String symbol);
    
    List<Stock> findByIsActiveTrue();
    List<Stock> findByExchangeAndIsActiveTrue(String exchange);
    List<Stock> findBySectorAndIsActiveTrue(String sector);

    @Query("SELECT DISTINCT s.sector FROM Stock s WHERE s.isActive = true AND s.sector IS NOT NULL ORDER BY s.sector")
    List<String> findAllActiveSectors();
}

