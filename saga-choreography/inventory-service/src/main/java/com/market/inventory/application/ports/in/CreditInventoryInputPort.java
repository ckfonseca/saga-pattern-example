package com.market.inventory.application.ports.in;

import com.market.inventory.application.core.domain.SaleVO;

public interface CreditInventoryInputPort {

    void credit(SaleVO saleVO);
}
