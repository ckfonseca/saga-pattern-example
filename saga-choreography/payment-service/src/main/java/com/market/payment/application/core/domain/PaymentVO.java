package com.market.payment.application.core.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class PaymentVO {

    private Long id;
    private Long userId;
    private Long saleId;
    private BigDecimal value;
    private LocalDateTime createdAt;

    public PaymentVO() {
    }

    public PaymentVO(Long id, Long userId, Long saleId, BigDecimal value, LocalDateTime createdAt) {
        this.id = id;
        this.userId = userId;
        this.saleId = saleId;
        this.value = value;
        this.createdAt = createdAt;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public Long getUserId() {
        return userId;
    }

    public void setUserId(Long userId) {
        this.userId = userId;
    }

    public Long getSaleId() {
        return saleId;
    }

    public void setSaleId(Long saleId) {
        this.saleId = saleId;
    }

    public BigDecimal getValue() {
        return value;
    }

    public void setValue(BigDecimal value) {
        this.value = value;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }
}
