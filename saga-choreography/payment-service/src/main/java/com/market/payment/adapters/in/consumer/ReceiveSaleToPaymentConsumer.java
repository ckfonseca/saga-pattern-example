package com.market.payment.adapters.in.consumer;

import com.market.payment.adapters.out.message.SaleMessage;
import com.market.payment.application.core.domain.enums.SaleEventEnum;
import com.market.payment.application.ports.in.SalePaymentInputPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Slf4j
@Component
public class ReceiveSaleToPaymentConsumer {

    private final SalePaymentInputPort salePaymentInputPort;

    @KafkaListener(topics = "${application-config.kafka.topic}", groupId = "${application-config.kafka.consumer.group-id}")
    public void receive(SaleMessage saleMessage) {
        if(SaleEventEnum.UPDATED_INVENTORY.equals(saleMessage.getSaleEvent())) {
            log.info("Beginning of payment.");
            this.salePaymentInputPort.payment(saleMessage.getSale());
            log.info("End of payment.");
        }
    }
}
