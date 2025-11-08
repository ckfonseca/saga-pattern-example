package com.market.sale.adapters.out.repository.entity;

import jakarta.persistence.Column;
import jakarta.persistence.Entity;
import jakarta.persistence.GeneratedValue;
import jakarta.persistence.GenerationType;
import jakarta.persistence.Id;
import jakarta.persistence.PrePersist;
import jakarta.persistence.PreUpdate;
import java.math.BigDecimal;
import java.time.LocalDateTime;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
@Entity(name = "sales")
public class SaleEntity {

  @Id
  @GeneratedValue(strategy = GenerationType.IDENTITY)
  private Long id;
  private Integer productId;
  private Integer userId;
  private BigDecimal value;
  private Integer saleStatusId;
  private Integer quantity;
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
