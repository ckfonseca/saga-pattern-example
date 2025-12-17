package com.market.inventory.application.ports.out;

import com.market.inventory.application.core.domain.InventoryVO;

public interface UpdateInventoryOutputPort {

    void update(InventoryVO inventoryVO);
}
