package com.stockanalyzer.backend.repository;

import com.stockanalyzer.backend.model.BacktestResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;

@Repository
public interface BacktestResultRepository extends JpaRepository<BacktestResult, Long> {
    List<BacktestResult> findByUser_UsernameOrderByCreatedAtDesc(String username);
}
