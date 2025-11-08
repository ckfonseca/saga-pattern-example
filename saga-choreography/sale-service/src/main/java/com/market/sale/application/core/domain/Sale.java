package com.market.sale.application.core.domain;

import com.market.sale.application.core.domain.enums.SaleStatusEnum;
import java.math.BigDecimal;
import java.time.LocalDateTime;

public class Sale {

  private Long id;
  private Long productId;
  private Long userId;
  private BigDecimal value;
  private SaleStatusEnum saleStatus;
  private Integer quantity;
  private LocalDateTime createdAt;

  public Sale() {

  }

  public Sale(Long id, Long productId, Long userId, BigDecimal value, SaleStatusEnum saleStatus,
      Integer quantity, LocalDateTime createdAt
  ) {
    this.id = id;
    this.productId = productId;
    this.userId = userId;
    this.value = value;
    this.saleStatus = saleStatus;
    this.quantity = quantity;
    this.createdAt = createdAt;
  }

  public Long getId() {
    return id;
  }

  public void setId(Long id) {
    this.id = id;
  }

  public Long getProductId() {
    return productId;
  }

  public void setProductId(Long productId) {
    this.productId = productId;
  }

  public Long getUserId() {
    return userId;
  }

  public void setUserId(Long userId) {
    this.userId = userId;
  }

  public BigDecimal getValue() {
    return value;
  }

  public void setValue(BigDecimal value) {
    this.value = value;
  }

  public SaleStatusEnum getSaleStatus() {
    return saleStatus;
  }

  public void setSaleStatus(SaleStatusEnum saleStatus) {
    this.saleStatus = saleStatus;
  }

  public Integer getQuantity() {

    return quantity;
  }

  public void setQuantity(Integer quantity) {
    this.quantity = quantity;
  }

  public LocalDateTime getCreatedAt() {
    return createdAt;
  }

  public void setCreatedAt(LocalDateTime createdAt) {
    this.createdAt = createdAt;
  }
}
