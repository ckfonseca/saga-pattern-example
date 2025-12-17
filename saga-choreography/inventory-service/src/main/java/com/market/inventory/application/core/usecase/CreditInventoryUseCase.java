package com.market.inventory.application.core.usecase;

import com.market.inventory.application.core.domain.SaleVO;
import com.market.inventory.application.core.domain.enums.SaleEventEnum;
import com.market.inventory.application.ports.in.CreditInventoryInputPort;
import com.market.inventory.application.ports.in.FindInventoryByProductIdInputPort;
import com.market.inventory.application.ports.out.SendToKafkaOutputPort;
import com.market.inventory.application.ports.out.UpdateInventoryOutputPort;

public class CreditInventoryUseCase implements CreditInventoryInputPort {
    private final FindInventoryByProductIdInputPort findInventoryByProductIdInputPort;
    private final UpdateInventoryOutputPort updateInventoryOutputPort;
    private final SendToKafkaOutputPort sendToKafkaOutputPort;

    public CreditInventoryUseCase(
            FindInventoryByProductIdInputPort findInventoryByProductIdInputPort,
            UpdateInventoryOutputPort updateInventoryOutputPort,
            SendToKafkaOutputPort sendToKafkaOutputPort
    ) {
        this.findInventoryByProductIdInputPort = findInventoryByProductIdInputPort;
        this.updateInventoryOutputPort = updateInventoryOutputPort;
        this.sendToKafkaOutputPort = sendToKafkaOutputPort;
    }

    @Override
    public void credit(SaleVO saleVO) {
        var inventory = this.findInventoryByProductIdInputPort.find(saleVO.getProductId());
        inventory.creditQuantity(saleVO.getQuantity());
        this.updateInventoryOutputPort.update(inventory);
        this.sendToKafkaOutputPort.send(saleVO, SaleEventEnum.ROLLBACK_INVENTORY);
    }
}
