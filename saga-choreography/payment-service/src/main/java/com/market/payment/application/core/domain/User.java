package com.market.payment.application.core.domain;

import java.math.BigDecimal;
import java.time.LocalDateTime;

public class User {
    private Long id;
    private String name;
    private BigDecimal balance;
    private LocalDateTime createdAt;

    public User() {}

    public User(Long id, String name, BigDecimal balance) {
        this.id = id;
        this.name = name;
        this.balance = balance;
    }

    public Long getId() {
        return id;
    }

    public void setId(Long id) {
        this.id = id;
    }

    public String getName() {
        return name;
    }

    public void setName(String name) {
        this.name = name;
    }

    public BigDecimal getBalance() {
        return balance;
    }

    public void setBalance(BigDecimal balance) {
        this.balance = balance;
    }

    public LocalDateTime getCreatedAt() {
        return createdAt;
    }

    public void setCreatedAt(LocalDateTime createdAt) {
        this.createdAt = createdAt;
    }

    public void debitBalance(BigDecimal value) {
        this.balance = this.balance.subtract(value);
    }
}
