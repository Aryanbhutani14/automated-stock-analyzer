package com.stockanalyzer.backend.repository;

import com.stockanalyzer.backend.model.Stock;
import com.stockanalyzer.backend.model.StockPrice;
import org.springframework.data.jpa.repository.JpaRepository;
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
}
