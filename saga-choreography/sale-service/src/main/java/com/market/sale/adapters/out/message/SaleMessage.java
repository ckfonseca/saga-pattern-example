package com.market.sale.adapters.out.message;

import com.market.sale.application.core.domain.Sale;
import com.market.sale.application.core.domain.enums.SaleEventEnum;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;
import lombok.ToString;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleMessage {

  private Sale sale;
  private SaleEventEnum saleEvent;
}
