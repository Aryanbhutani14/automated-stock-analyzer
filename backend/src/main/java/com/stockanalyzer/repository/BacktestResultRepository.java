package com.stockanalyzer.repository;

import com.stockanalyzer.entity.BacktestResult;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface BacktestResultRepository extends JpaRepository<BacktestResult, Long> {

    List<BacktestResult> findByUser_IdOrderByCreatedAtDesc(Long userId);
}
