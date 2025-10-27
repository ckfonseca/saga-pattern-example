package com.market.inventory.config.usecase;

import com.market.inventory.adapters.out.SendToKafkaAdapter;
import com.market.inventory.adapters.out.UpdateInventoryAdapter;
import com.market.inventory.application.core.usecase.DebitInventoryUseCase;
import com.market.inventory.application.core.usecase.FindInventoryByProductIdUseCase;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class DebitInventoryConfig {

    @Bean
    public DebitInventoryUseCase debitInventoryUseCase(
            FindInventoryByProductIdUseCase findInventoryByProductIdUseCase,
            UpdateInventoryAdapter updateInventoryAdapter,
            SendToKafkaAdapter sendToKafkaAdapter
    ) {
        return new DebitInventoryUseCase(findInventoryByProductIdUseCase, updateInventoryAdapter, sendToKafkaAdapter);

    }
}
