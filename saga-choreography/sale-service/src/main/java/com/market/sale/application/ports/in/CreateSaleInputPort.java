package com.market.sale.application.ports.in;

import com.market.sale.application.core.domain.SaleVO;

public interface CreateSaleInputPort {

  void create(SaleVO saleVO);
}
