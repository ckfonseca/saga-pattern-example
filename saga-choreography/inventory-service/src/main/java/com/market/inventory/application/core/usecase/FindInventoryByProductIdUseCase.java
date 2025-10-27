package com.market.inventory.application.core.usecase;

import com.market.inventory.application.core.domain.Inventory;
import com.market.inventory.application.ports.in.FindInventoryByProductIdInputPort;
import com.market.inventory.application.ports.out.FindInventoryByProductIdOutputPort;

public class FindInventoryByProductIdUseCase implements FindInventoryByProductIdInputPort {

    private final FindInventoryByProductIdOutputPort findInventoryByProductIdOutputPort;

    public FindInventoryByProductIdUseCase(FindInventoryByProductIdOutputPort findInventoryByProductIdOutputPort) {
        this.findInventoryByProductIdOutputPort = findInventoryByProductIdOutputPort;
    }

    @Override
    public Inventory find(Integer productId) {

        return findInventoryByProductIdOutputPort.find(productId).orElseThrow(
                () -> new RuntimeException("Not found inventory by this product.")
        );
    }
}
