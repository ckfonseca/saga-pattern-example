package com.market.inventory.application.ports.in;

import com.market.inventory.application.core.domain.SaleVO;

public interface DebitInventoryInputPort {

    void debit(SaleVO saleVO);
}
