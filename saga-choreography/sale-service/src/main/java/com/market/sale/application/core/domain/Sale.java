package com.market.sale.application.core.domain;

import com.market.sale.application.core.domain.enums.SaleStatusEnum;
import java.math.BigDecimal;

public class Sale {

  private Long id;
  private Integer productId;
  private Integer userId;
  private BigDecimal value;
  private SaleStatusEnum saleStatus;
  private Integer quantity;

  public Sale() {

  }

  public Sale(
      Long id,
      Integer productId,
      Integer userId,
      BigDecimal value,
      SaleStatusEnum saleStatus,
      Integer quantity
  ) {
    this.id = id;
    this.productId = productId;
    this.userId = userId;
    this.value = value;
    this.saleStatus = saleStatus;
    this.quantity = quantity;
  }

  public Long getId() {

    return id;
  }

  public void setId(Long id) {

    this.id = id;
  }

  public Integer getProductId() {

    return productId;
  }

  public void setProductId(Integer productId) {

    this.productId = productId;
  }

  public Integer getUserId() {

    return userId;
  }

  public void setUserId(Integer userId) {

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
}
