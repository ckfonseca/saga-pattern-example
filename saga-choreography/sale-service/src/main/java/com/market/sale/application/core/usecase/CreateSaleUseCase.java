package com.market.sale.application.core.usecase;

import com.market.sale.application.core.domain.Sale;
import com.market.sale.application.core.domain.enums.SaleEventEnum;
import com.market.sale.application.core.domain.enums.SaleStatusEnum;
import com.market.sale.application.ports.in.CreateSaleInputPort;
import com.market.sale.application.ports.out.SaveSaleOutputPort;
import com.market.sale.application.ports.out.SendCreatedSaleOutputPort;

public class CreateSaleUseCase implements CreateSaleInputPort {

  private final SaveSaleOutputPort saveSaleOutputPort;
  private final SendCreatedSaleOutputPort sendCreatedSaleOutputPort;

  public CreateSaleUseCase(SaveSaleOutputPort saveSaleOutputPort,
      SendCreatedSaleOutputPort sendCreatedSaleOutputPort) {
    this.saveSaleOutputPort = saveSaleOutputPort;
    this.sendCreatedSaleOutputPort = sendCreatedSaleOutputPort;
  }

  @Override
  public void create(Sale sale) {
    sale.setSaleStatus(SaleStatusEnum.PENDING);
    var saleResponse = this.saveSaleOutputPort.save(sale);
    this.sendCreatedSaleOutputPort.send(saleResponse, SaleEventEnum.CREATED_SALE);
  }
}
