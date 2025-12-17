package com.market.sale.application.core.usecase;

import com.market.sale.application.core.domain.SaleVO;
import com.market.sale.application.core.domain.enums.SaleStatusEnum;
import com.market.sale.application.ports.in.FinalizeSaleInputPort;
import com.market.sale.application.ports.in.FindSaleByIdInputPort;
import com.market.sale.application.ports.out.SaveSaleOutputPort;

public class FinalizeSaleUseCase implements FinalizeSaleInputPort {

  private final FindSaleByIdInputPort findSaleByIdInputPort;
  private final SaveSaleOutputPort saveSaleOutputPort;

  public FinalizeSaleUseCase(
      FindSaleByIdInputPort findSaleByIdInputPort,
      SaveSaleOutputPort saveSaleOutputPort
  ) {
    this.findSaleByIdInputPort = findSaleByIdInputPort;
    this.saveSaleOutputPort = saveSaleOutputPort;
  }

  @Override
  public void finalize(SaleVO saleVO) {
    var saleResponse = this.findSaleByIdInputPort.find(saleVO.getId());
    saleResponse.setSaleStatus(SaleStatusEnum.FINALIZED);
    this.saveSaleOutputPort.save(saleResponse);
  }
}
