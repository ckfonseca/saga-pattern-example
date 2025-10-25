package com.market.sale.application.ports.out;

import com.market.sale.application.core.domain.Sale;

public interface SaveSaleOutputPort {

  Sale save(Sale sale);
}
