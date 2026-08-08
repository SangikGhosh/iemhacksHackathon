package com.iem.market;

import com.iem.model.WalletTransaction;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.math.BigDecimal;
import java.util.UUID;

public interface WalletTransactionRepository extends JpaRepository<WalletTransaction, UUID> {

    Page<WalletTransaction> findByUserId(UUID userId, Pageable pageable);

    @Query("""
           select coalesce(sum(t.amount), 0) from WalletTransaction t
            where t.userId = :userId and t.type = com.iem.enums.TransactionType.CREDIT
           """)
    BigDecimal totalCredited(@Param("userId") UUID userId);

    @Query("""
           select coalesce(sum(t.amount), 0) from WalletTransaction t
            where t.userId = :userId and t.type = com.iem.enums.TransactionType.DEBIT
           """)
    BigDecimal totalDebited(@Param("userId") UUID userId);
}
