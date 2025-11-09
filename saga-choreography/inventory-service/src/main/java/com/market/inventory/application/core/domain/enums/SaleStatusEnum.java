package com.market.inventory.application.core.domain.enums;

import lombok.Getter;

import java.util.Arrays;

public enum SaleStatusEnum {

    PENDING(1),
    FINALIZED(2),
    CANCELED(3);

    @Getter
    private final Integer id;

    SaleStatusEnum(Integer id) {
        this.id = id;
    }

    public static SaleStatusEnum findById(Integer id) {
        return Arrays.stream(values()).filter(
                        saleStatusEnum -> saleStatusEnum.getId().equals(id)).
                findFirst().orElseThrow(
                        () ->  new IllegalArgumentException(String.format("The id %d is invalid.", id))
                );
    }
}
