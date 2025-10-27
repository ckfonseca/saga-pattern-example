package com.market.inventory.adapters.out;

import com.market.inventory.adapters.out.repository.InventoryRepository;
import com.market.inventory.adapters.out.repository.mapper.InventoryEntityMapper;
import com.market.inventory.application.core.domain.Inventory;
import com.market.inventory.application.ports.out.FindInventoryByProductIdOutputPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;

@RequiredArgsConstructor
@Component
public class FindInventoryByProductIdAdapter implements FindInventoryByProductIdOutputPort {

    private final InventoryRepository inventoryRepository;
    private final InventoryEntityMapper inventoryEntityMapper;

    @Override
    public Optional<Inventory> find(Integer productId) {
        var inventoryEntity = this.inventoryRepository.findByProductId(productId);

        return inventoryEntity.map(this.inventoryEntityMapper::inventoryEntityToInventory);
    }
}
