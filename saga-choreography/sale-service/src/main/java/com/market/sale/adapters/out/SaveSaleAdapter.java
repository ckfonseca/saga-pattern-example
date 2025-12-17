package com.market.sale.adapters.out;

import com.market.sale.adapters.out.repository.SaleRepository;
import com.market.sale.adapters.out.repository.mapper.SaleEntityMapper;
import com.market.sale.application.core.domain.SaleVO;
import com.market.sale.application.ports.out.SaveSaleOutputPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Component
public class SaveSaleAdapter implements SaveSaleOutputPort {

  private final SaleRepository saleRepository;
  private final SaleEntityMapper saleEntityMapper;

  @Override
  public SaleVO save(SaleVO saleVO) {
    var saleEntity = this.saleEntityMapper.saleVOToSaleEntity(saleVO);
    var saleEntityResponse = this.saleRepository.save(saleEntity);

    return this.saleEntityMapper.saleEntityToSaleVO(saleEntityResponse);
  }
}
