package com.stockanalyzer.backend.repository;

import com.stockanalyzer.backend.model.AiSummary;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.time.LocalDate;
import java.util.Optional;

@Repository
public interface AiSummaryRepository extends JpaRepository<AiSummary, Long> {
    Optional<AiSummary> findByStock_IdAndSummaryDate(Long stockId, LocalDate date);
}
