package com.market.sale.application.ports.out;

import com.market.sale.application.core.domain.SaleVO;
import java.util.Optional;

public interface FindSaleByIdOutputPort {

  Optional<SaleVO> find(Long id);
}
