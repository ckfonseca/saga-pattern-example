package com.market.inventory.application.ports.out;

import com.market.inventory.application.core.domain.InventoryVO;

import java.util.Optional;

public interface FindInventoryByProductIdOutputPort {

    Optional<InventoryVO> find(final Long productId);
}
