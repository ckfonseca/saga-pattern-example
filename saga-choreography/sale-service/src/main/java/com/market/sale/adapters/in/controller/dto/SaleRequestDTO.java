package com.market.sale.adapters.in.controller.request;

import jakarta.validation.constraints.NotNull;
import java.math.BigDecimal;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleRequest {

  @NotNull
  private Integer userId;
  @NotNull
  private Integer productId;
  @NotNull
  private Integer quantity;
  @NotNull
  private BigDecimal value;
}
