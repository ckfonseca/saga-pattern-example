package com.market.inventory.adapters.out.repository;

import com.market.inventory.adapters.out.repository.entity.InventoryEntity;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface InventoryRepository extends JpaRepository<InventoryEntity, Long> {
    Optional<InventoryEntity> findByProductId(Integer productId);
}
