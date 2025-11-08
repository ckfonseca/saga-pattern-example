package com.market.payment.adapters.out.repository.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity(name = "users")
public class UserEntity {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;
    private String name;
    private BigDecimal balance;
    @Column(columnDefinition = "TIMESTAMP", nullable = false)
    private LocalDateTime createdAt;
    @Column(columnDefinition = "TIMESTAMP")
    private LocalDateTime updatedAt;

    @PrePersist
    void onCreate() {
        this.setCreatedAt(LocalDateTime.now());
    }

    @PreUpdate
    void onUpdate() {
        this.setUpdatedAt(LocalDateTime.now());
    }
}
