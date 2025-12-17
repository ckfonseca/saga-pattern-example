package com.market.inventory.adapters.out.repository.mapper;

import com.market.inventory.adapters.out.repository.entity.InventoryEntity;
import com.market.inventory.application.core.domain.InventoryVO;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface InventoryEntityMapper {

    InventoryVO inventoryEntityToInventoryVO(InventoryEntity inventoryEntity);
    InventoryEntity inventoryVOToInventoryEntity(InventoryVO inventoryVO);
}
