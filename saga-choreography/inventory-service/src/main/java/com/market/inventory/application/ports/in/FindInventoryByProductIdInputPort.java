package com.market.inventory.application.ports.in;

import com.market.inventory.application.core.domain.Inventory;

public interface FindInventoryByProductIdInputPort {

    Inventory find(Integer productId);
}
