package com.market.inventory.application.ports.in;

import com.market.inventory.application.core.domain.Sale;

public interface CreditInventoryInputPort {

    void credit(Sale sale);
}
