package com.stockanalyzer.repository;

import com.stockanalyzer.entity.AiSummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDate;
import java.util.Optional;

@Repository
public interface AiSummaryRepository extends JpaRepository<AiSummary, Long> {

    Optional<AiSummary> findByStock_IdAndSummaryDate(Long stockId, LocalDate date);

    @Query("""
        SELECT a FROM AiSummary a
        WHERE a.stock.id = :stockId
        ORDER BY a.summaryDate DESC
        LIMIT 1
        """)
    Optional<AiSummary> findLatestByStockId(@Param("stockId") Long stockId);
}
