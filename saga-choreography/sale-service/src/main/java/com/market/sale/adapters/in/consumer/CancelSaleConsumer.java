package com.market.sale.adapters.in.consumer;

import com.market.sale.adapters.out.message.SaleMessageDTO;
import com.market.sale.application.core.domain.enums.SaleEventEnum;
import com.market.sale.application.ports.in.CancelSaleInputPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Slf4j
@RequiredArgsConstructor
@Component
public class CancelSaleConsumer {

  private final CancelSaleInputPort cancelSaleInputPort;

  @KafkaListener(topics = "${application-config.kafka.topic}", groupId = "${application-config.kafka.consumer.group-id.cancel}")
  public void receive(SaleMessageDTO saleMessageDTO) {
    if(SaleEventEnum.ROLLBACK_INVENTORY.equals(saleMessageDTO.getSaleEvent())) {
      log.info("Canceling the sale...");
      this.cancelSaleInputPort.cancel(saleMessageDTO.getSaleVO());
      log.info("Sale canceled");
    }
  }
}
