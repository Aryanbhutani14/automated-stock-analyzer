package com.stockanalyzer.backend.repository;

import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.List;
import java.util.Optional;

@Repository
public interface StockPriceRepository extends JpaRepository<StockPrice, Long> {
    List<StockPrice> findByStockOrderByTradeDateAsc(Stock stock);
    Optional<StockPrice> findByStockAndTradeDate(Stock stock, LocalDate tradeDate);
    Optional<StockPrice> findFirstByStockOrderByTradeDateDesc(Stock stock);
    List<StockPrice> findTop2ByStockOrderByTradeDateDesc(Stock stock);

    Optional<StockPrice> findByStock_IdAndTradeDate(Long stockId, LocalDate tradeDate);

    @Query("""
        SELECT sp FROM StockPrice sp
        WHERE sp.stock.id = :stockId
        ORDER BY sp.tradeDate DESC
        LIMIT :limit
        """)
    List<StockPrice> findLatestNByStockId(@Param("stockId") Long stockId,
                                          @Param("limit")   int limit);

    @Query("""
        SELECT sp FROM StockPrice sp
        WHERE sp.stock.id = :stockId
        ORDER BY sp.tradeDate DESC
        LIMIT 1
        """)
    Optional<StockPrice> findLatestByStockId(@Param("stockId") Long stockId);

    List<StockPrice> findByStock_IdAndTradeDateBetweenOrderByTradeDateAsc(
            Long stockId, LocalDate from, LocalDate to);

    boolean existsByStock_IdAndTradeDate(Long stockId, LocalDate tradeDate);
}

