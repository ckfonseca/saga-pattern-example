package com.market.inventory.application.core.domain;

import java.time.LocalDateTime;

public class InventoryVO {

    private Long id;
    private Integer productId;
    private Integer quantity;
    private LocalDateTime createdAt;

    public InventoryVO() {
    }

    public InventoryVO(Long id, Integer productId, Integer quantity, LocalDateTime createdAt) {
        this.id = id;
        this.productId = productId;
        this.quantity = quantity;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public Integer getProductId() {
        return productId;
    }

    public Integer getQuantity() {
        return quantity;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public void setProductId(Integer productId) {
        this.productId = productId;
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

    public void debitQuantity(Integer quantity) {
        this.quantity -= quantity;
    }

    public void creditQuantity(Integer quantity) {
        this.quantity += quantity;
    }
}
