package com.market.inventory.adapters.out.repository.mapper;

import com.market.inventory.adapters.out.repository.entity.InventoryEntity;
import com.market.inventory.application.core.domain.Inventory;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;

@Mapper(componentModel = "spring")
public interface InventoryEntityMapper {

    Inventory inventoryEntityToInventory(InventoryEntity inventoryEntity);
    InventoryEntity inventoryToInventoryEntity(Inventory inventory);
}
