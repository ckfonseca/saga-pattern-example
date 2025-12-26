package com.market.inventory.adapters.in.consumer;


import com.market.inventory.adapters.out.message.SaleMessage;
import com.market.inventory.application.core.domain.enums.SaleEventEnum;
import com.market.inventory.application.ports.in.DebitInventoryInputPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Slf4j
@Component
public class ReceiveSaleToDebitInventoryConsumer {

    private final DebitInventoryInputPort debitInventoryInputPort;

    @KafkaListener(topics = "${application-config.kafka.topic}", groupId = "${application-config.kafka.consumer.group-id.debit}")
    public void receive(SaleMessage saleMessage) {
        if(SaleEventEnum.CREATED_SALE.equals(saleMessage.getSaleEvent())) {
            log.info("Beginning of merchandise separation.");
            this.debitInventoryInputPort.debit(saleMessage.getSale());
            log.info("End of merchandise separation.");
        }
    }
}


