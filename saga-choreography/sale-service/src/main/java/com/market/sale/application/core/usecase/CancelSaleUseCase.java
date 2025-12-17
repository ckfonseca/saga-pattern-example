package com.market.sale.application.core.usecase;

import com.market.sale.application.core.domain.SaleVO;
import com.market.sale.application.core.domain.enums.SaleStatusEnum;
import com.market.sale.application.ports.in.CancelSaleInputPort;
import com.market.sale.application.ports.in.FindSaleByIdInputPort;
import com.market.sale.application.ports.out.SaveSaleOutputPort;

public class CancelSaleUseCase implements CancelSaleInputPort {

  private final FindSaleByIdInputPort findSaleByIdInputPort;
  private final SaveSaleOutputPort saveSaleOutputPort;

  public CancelSaleUseCase(
      FindSaleByIdInputPort findSaleByIdInputPort,
      SaveSaleOutputPort saveSaleOutputPort
  ) {
    this.findSaleByIdInputPort = findSaleByIdInputPort;
    this.saveSaleOutputPort = saveSaleOutputPort;
  }

  @Override
  public void cancel(SaleVO saleVO) {
    var saleResponse = this.findSaleByIdInputPort.find(saleVO.getId());
    saleResponse.setSaleStatus(SaleStatusEnum.CANCELED);
    this.saveSaleOutputPort.save(saleResponse);
  }
}
