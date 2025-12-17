package com.market.sale.application.core.usecase;

import com.market.sale.application.core.domain.SaleVO;
import com.market.sale.application.ports.in.FindSaleByIdInputPort;
import com.market.sale.application.ports.out.FindSaleByIdOutputPort;

public class FindSaleByIdUseCase implements FindSaleByIdInputPort {

  private final FindSaleByIdOutputPort findSaleByIdOutputPort;

  public FindSaleByIdUseCase(FindSaleByIdOutputPort findSaleByIdOutputPort) {
    this.findSaleByIdOutputPort = findSaleByIdOutputPort;
  }

  @Override
  public SaleVO find(final Long id) {
    return this.findSaleByIdOutputPort.find(id).orElseThrow(
        () -> new RuntimeException("Sale not found!")
    );
  }
}
