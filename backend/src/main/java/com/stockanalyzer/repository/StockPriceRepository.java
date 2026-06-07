package com.stockanalyzer.repository;

import com.stockanalyzer.entity.StockPrice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface StockPriceRepository extends JpaRepository<StockPrice, Long> {

    Optional<StockPrice> findByStock_IdAndTradeDate(Long stockId, LocalDate tradeDate);

    /** Latest N prices for a stock (used for indicator calculation) */
    @Query("""
        SELECT sp FROM StockPrice sp
        WHERE sp.stock.id = :stockId
        ORDER BY sp.tradeDate DESC
        LIMIT :limit
        """)
    List<StockPrice> findLatestNByStockId(@Param("stockId") Long stockId,
                                          @Param("limit")   int limit);

    /** Price history between two dates */
    List<StockPrice> findByStock_IdAndTradeDateBetweenOrderByTradeDateAsc(
            Long stockId, LocalDate from, LocalDate to);

    /** Most recent price for a stock */
    @Query("""
        SELECT sp FROM StockPrice sp
        WHERE sp.stock.id = :stockId
        ORDER BY sp.tradeDate DESC
        LIMIT 1
        """)
    Optional<StockPrice> findLatestByStockId(@Param("stockId") Long stockId);

    /** Check if data already loaded for a date */
    boolean existsByStock_IdAndTradeDate(Long stockId, LocalDate tradeDate);
}
