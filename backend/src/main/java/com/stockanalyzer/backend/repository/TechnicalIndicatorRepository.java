package com.stockanalyzer.backend.repository;

import com.stockanalyzer.backend.model.TechnicalIndicator;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;
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

    @Query("""
        SELECT ti FROM TechnicalIndicator ti
        WHERE ti.stock.id = :stockId
        ORDER BY ti.tradeDate DESC
        LIMIT 2
        """)
    List<TechnicalIndicator> findTop2ByStockIdOrderByTradeDateDesc(@Param("stockId") Long stockId);

    boolean existsByStock_IdAndTradeDate(Long stockId, LocalDate tradeDate);
}

