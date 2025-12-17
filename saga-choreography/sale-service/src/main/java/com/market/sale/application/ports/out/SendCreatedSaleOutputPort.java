package com.market.sale.application.ports.out;

import com.market.sale.application.core.domain.SaleVO;
import com.market.sale.application.core.domain.enums.SaleEventEnum;

public interface SendCreatedSaleOutputPort {

  void send(SaleVO saleVO, SaleEventEnum saleEvent);
}
