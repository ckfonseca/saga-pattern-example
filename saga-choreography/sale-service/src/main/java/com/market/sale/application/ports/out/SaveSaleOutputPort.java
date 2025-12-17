package com.market.sale.application.ports.out;

import com.market.sale.application.core.domain.SaleVO;

public interface SaveSaleOutputPort {

  SaleVO save(SaleVO saleVO);
}
