package com.stockanalyzer.backend.repository;

import com.stockanalyzer.backend.model.Alert;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;
import java.util.List;
import java.util.Optional;

@Repository
public interface AlertRepository extends JpaRepository<Alert, Long> {
    List<Alert> findByUser_UsernameOrderByStock_SymbolAsc(String username);
    List<Alert> findByActiveTrueOrderByStock_SymbolAsc();
    Optional<Alert> findByIdAndUser_Username(Long id, String username);
}
