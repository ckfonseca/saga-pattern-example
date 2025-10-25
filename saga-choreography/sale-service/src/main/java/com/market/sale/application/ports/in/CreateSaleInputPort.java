package com.market.sale.application.ports.in;

import com.market.sale.application.core.domain.Sale;

public interface CreateSaleInputPort {

  void create(Sale sale);
}
