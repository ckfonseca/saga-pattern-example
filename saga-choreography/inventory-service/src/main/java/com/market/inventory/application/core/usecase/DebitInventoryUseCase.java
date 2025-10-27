package com.market.inventory.application.core.usecase;

import com.market.inventory.application.core.domain.enums.SaleEventEnum;
import com.market.inventory.application.core.domain.Sale;
import com.market.inventory.application.ports.in.DebitInventoryInputPort;
import com.market.inventory.application.ports.in.FindInventoryByProductIdInputPort;
import com.market.inventory.application.ports.out.SendToKafkaOutputPort;
import com.market.inventory.application.ports.out.UpdateInventoryOutputPort;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class DebitInventoryUseCase implements DebitInventoryInputPort {

    private final FindInventoryByProductIdInputPort findInventoryByProductIdInputPort;
    private final UpdateInventoryOutputPort updateInventoryOutputPort;
    private final SendToKafkaOutputPort sendToKafkaOutputPort;

    public DebitInventoryUseCase(FindInventoryByProductIdInputPort findInventoryByProductIdInputPort,
                                 UpdateInventoryOutputPort updateInventoryOutputPort,
                                 SendToKafkaOutputPort sendToKafkaOutputPort) {

        this.findInventoryByProductIdInputPort = findInventoryByProductIdInputPort;
        this.updateInventoryOutputPort = updateInventoryOutputPort;
        this.sendToKafkaOutputPort = sendToKafkaOutputPort;
    }

    @Override
    public void debit(Sale sale) {
        try {
            var inventory = this.findInventoryByProductIdInputPort.find(sale.getProductId());
            if(inventory.getQuantity() < sale.getQuantity()) {
                throw new RuntimeException("Insufficient quantity");
            }
            inventory.debitQuantity(sale.getQuantity());
            this.updateInventoryOutputPort.update(inventory);
            this.sendToKafkaOutputPort.send(sale, SaleEventEnum.UPDATED_INVENTORY);
        } catch (Exception e) {
            log.error("An error occurred: {}", e.getMessage());
            this.sendToKafkaOutputPort.send(sale, SaleEventEnum.ROLLBACK_INVENTORY);
        }
    }
}
