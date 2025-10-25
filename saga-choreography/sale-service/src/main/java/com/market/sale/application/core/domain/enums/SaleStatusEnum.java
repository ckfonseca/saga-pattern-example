package com.market.sale.application.core.domain.enums;

import java.util.Arrays;
import lombok.Getter;

@Getter
public enum SaleStatusEnum {

  PENDING(1),
  FINALIZED(2),
  CANCELED(3);

  private final int id;

  SaleStatusEnum(int id) {

    this.id = id;
  }

  public static SaleStatusEnum toEnum(int id) {
    return Arrays.stream(values()).filter(
            saleStatusEnum -> saleStatusEnum.getId() == id).
        findFirst().orElseThrow(
            () -> new IllegalArgumentException(String.format("The id %d is invalid.", id))
        );
  }
}
