package com.market.sale.adapters.out;

import com.market.sale.adapters.out.repository.SaleRepository;
import com.market.sale.adapters.out.repository.mapper.SaleEntityMapper;
import com.market.sale.application.core.domain.Sale;
import com.market.sale.application.ports.out.FindSaleByIdOutputPort;
import java.util.Optional;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Component
public class FindSaleByIdAdapter implements FindSaleByIdOutputPort {

  private final SaleRepository saleRepository;
  private final SaleEntityMapper saleEntityMapper;

  @Override
  public Optional<Sale> find(Long id) {
    var saleEntity = this.saleRepository.findById(id);

    return saleEntity.map(this.saleEntityMapper::saleEntityToSale);
  }
}
