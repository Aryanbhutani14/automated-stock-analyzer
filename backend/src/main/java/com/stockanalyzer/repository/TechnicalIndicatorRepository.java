package com.stockanalyzer.repository;

import com.stockanalyzer.entity.TechnicalIndicator;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;

@Repository
public interface TechnicalIndicatorRepository extends JpaRepository<TechnicalIndicator, Long> {

    Optional<TechnicalIndicator> findByStock_IdAndTradeDate(Long stockId, LocalDate tradeDate);

    @Query("""
        SELECT ti FROM TechnicalIndicator ti
        WHERE ti.stock.id = :stockId
        ORDER BY ti.tradeDate DESC
        LIMIT 1
        """)
    Optional<TechnicalIndicator> findLatestByStockId(@Param("stockId") Long stockId);

    boolean existsByStock_IdAndTradeDate(Long stockId, LocalDate tradeDate);
}
