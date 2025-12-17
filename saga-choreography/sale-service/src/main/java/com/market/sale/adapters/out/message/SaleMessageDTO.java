package com.market.sale.adapters.out.message;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.market.sale.application.core.domain.SaleVO;
import com.market.sale.application.core.domain.enums.SaleEventEnum;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleMessageDTO {

  @JsonProperty("sale")
  private SaleVO saleVO;
  private SaleEventEnum saleEvent;
}
