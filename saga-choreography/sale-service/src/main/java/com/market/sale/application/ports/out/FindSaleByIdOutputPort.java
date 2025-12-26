package com.market.sale.application.ports.out;

import com.market.sale.application.core.domain.Sale;
import java.util.Optional;

public interface FindSaleByIdOutputPort {

  Optional<Sale> find(Long id);
}
