package com.market.sale.application.ports.in;

import com.market.sale.application.core.domain.SaleVO;

public interface FindSaleByIdInputPort {

  SaleVO find(final Long id);
}
