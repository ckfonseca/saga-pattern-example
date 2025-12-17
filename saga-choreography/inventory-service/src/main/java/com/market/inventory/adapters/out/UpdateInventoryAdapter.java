package com.market.inventory.adapters.out;

import com.market.inventory.adapters.out.repository.InventoryRepository;
import com.market.inventory.adapters.out.repository.mapper.InventoryEntityMapper;
import com.market.inventory.application.core.domain.InventoryVO;
import com.market.inventory.application.ports.out.UpdateInventoryOutputPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Component
public class UpdateInventoryAdapter implements UpdateInventoryOutputPort {

    private final InventoryRepository inventoryRepository;
    private final InventoryEntityMapper inventoryEntityMapper;


    @Override
    public void update(InventoryVO inventoryVO) {
        var inventoryEntity = this.inventoryEntityMapper.inventoryVOToInventoryEntity(inventoryVO);

        this.inventoryRepository.save(inventoryEntity);
    }
}
