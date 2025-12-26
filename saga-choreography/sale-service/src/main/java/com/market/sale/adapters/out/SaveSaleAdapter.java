package com.market.sale.adapters.out;

import com.market.sale.adapters.out.repository.SaleRepository;
import com.market.sale.adapters.out.repository.mapper.SaleEntityMapper;
import com.market.sale.application.core.domain.Sale;
import com.market.sale.application.ports.out.SaveSaleOutputPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Component
public class SaveSaleAdapter implements SaveSaleOutputPort {

  private final SaleRepository saleRepository;
  private final SaleEntityMapper saleEntityMapper;

  @Override
  public Sale save(Sale sale) {
    var saleEntity = this.saleEntityMapper.saleToSaleEntity(sale);
    var saleEntityResponse = this.saleRepository.save(saleEntity);

    return this.saleEntityMapper.saleEntityToSale(saleEntityResponse);
  }
}
