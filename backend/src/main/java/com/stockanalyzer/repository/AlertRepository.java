package com.stockanalyzer.repository;

import com.stockanalyzer.entity.Alert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface AlertRepository extends JpaRepository<Alert, Long> {

    List<Alert> findByUser_IdAndActiveTrueOrderByCreatedAtDesc(Long userId);

    List<Alert> findByActiveTrueOrderByStock_SymbolAsc();

    Optional<Alert> findByIdAndUser_Id(Long alertId, Long userId);
}
