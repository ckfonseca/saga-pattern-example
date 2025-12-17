package com.market.inventory.adapters.in.consumer;

import com.market.inventory.adapters.out.message.SaleMessageDTO;
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
  public void receive(SaleMessageDTO saleMessageDTO) {
    if (SaleEventEnum.FAILED_PAYMENT.equals(saleMessageDTO.getSaleEvent())) {
      log.info("Beginning of merchandise return.");
      this.creditInventoryInputPort.credit(saleMessageDTO.getSaleVO());
      log.info("End of merchandise return.");
    }
  }
}
