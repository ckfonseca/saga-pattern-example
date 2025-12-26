package com.market.sale.application.ports.out;

import com.market.sale.application.core.domain.Sale;
import com.market.sale.application.core.domain.enums.SaleEventEnum;

public interface SendCreatedSaleOutputPort {

  void send(Sale sale, SaleEventEnum saleEvent);
}
