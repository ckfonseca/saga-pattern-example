package com.market.inventory.adapters.in.consumer;

import com.market.inventory.adapters.out.message.SaleMessage;
import com.market.inventory.application.core.domain.enums.SaleEventEnum;
import com.market.inventory.application.ports.in.CreditInventoryInputPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Slf4j
@Component
public class ReceiveSaleToCreditInventoryConsumer {

  private final CreditInventoryInputPort creditInventoryInputPort;

  @KafkaListener(topics = "${application-config.kafka.topic}", groupId = "${application-config.kafka.consumer.group-id.credit}")
  public void receive(SaleMessage saleMessage) {
    if (SaleEventEnum.FAILED_PAYMENT.equals(saleMessage.getSaleEvent())) {
      log.info("Beginning of merchandise return.");
      this.creditInventoryInputPort.credit(saleMessage.getSale());
      log.info("End of merchandise return.");
    }
  }
}
