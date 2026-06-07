package com.stockanalyzer.repository;

import com.stockanalyzer.entity.Signal;
import com.stockanalyzer.entity.Signal.SignalType;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.List;

@Repository
public interface SignalRepository extends JpaRepository<Signal, Long> {

    List<Signal> findBySignalDateOrderByStock_SymbolAsc(LocalDate date);

    List<Signal> findBySignalTypeAndSignalDateOrderByStock_SymbolAsc(
            SignalType type, LocalDate date);

    List<Signal> findByStock_SymbolIgnoreCaseOrderBySignalDateDesc(String symbol);

    /** Signals for a stock in a date range — used by backtester */
    @Query("""
        SELECT s FROM Signal s
        WHERE s.stock.id = :stockId
          AND s.signalDate BETWEEN :from AND :to
        ORDER BY s.signalDate ASC
        """)
    List<Signal> findByStockIdAndDateRange(
            @Param("stockId") Long stockId,
            @Param("from")    LocalDate from,
            @Param("to")      LocalDate to);
}
