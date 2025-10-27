package com.market.inventory.application.ports.out;

import com.market.inventory.application.core.domain.Inventory;

public interface UpdateInventoryOutputPort {

    void update(Inventory inventory);
}
