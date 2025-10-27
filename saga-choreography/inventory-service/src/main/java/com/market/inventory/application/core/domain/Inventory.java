package com.market.inventory.application.core.domain;

public class Inventory {
    private Long id;
    private Integer productId;
    private Integer quantity;

    public Inventory() {

    }

    public Inventory(Long id, Integer productId, Integer quantity) {
        this.id = id;
        this.productId = productId;
        this.quantity = quantity;
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

    public void debitQuantity(Integer quantity) {

        this.quantity -= quantity;
    }

    public void creditQuantity(Integer quantity) {

        this.quantity += quantity;
    }
}
