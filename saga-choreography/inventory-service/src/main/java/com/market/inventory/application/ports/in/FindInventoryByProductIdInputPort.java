package com.market.inventory.application.ports.in;

import com.market.inventory.application.core.domain.InventoryVO;

public interface FindInventoryByProductIdInputPort {

    InventoryVO find(Long productId);
}
