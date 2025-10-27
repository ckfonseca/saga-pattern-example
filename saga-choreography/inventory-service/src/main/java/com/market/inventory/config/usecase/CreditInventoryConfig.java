package com.market.inventory.config.usecase;

import com.market.inventory.adapters.out.SendToKafkaAdapter;
import com.market.inventory.adapters.out.UpdateInventoryAdapter;
import com.market.inventory.application.core.usecase.CreditInventoryUseCase;
import com.market.inventory.application.core.usecase.FindInventoryByProductIdUseCase;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CreditInventoryConfig {

    @Bean
    public CreditInventoryUseCase creditInventoryUseCase(
            FindInventoryByProductIdUseCase findInventoryByProductIdUseCase,
            UpdateInventoryAdapter updateInventoryAdapter,
            SendToKafkaAdapter sendToKafkaAdapter
    ) {
        return new CreditInventoryUseCase(findInventoryByProductIdUseCase, updateInventoryAdapter, sendToKafkaAdapter);
    }
}
