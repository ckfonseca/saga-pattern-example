package com.market.inventory.application.ports.in;

import com.market.inventory.application.core.domain.Sale;

public interface DebitInventoryInputPort {

    void debit(Sale sale);
}
