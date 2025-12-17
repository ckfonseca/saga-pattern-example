package com.market.sale.adapters.in.consumer;

import com.market.sale.adapters.out.message.SaleMessageDTO;
import com.market.sale.application.core.domain.enums.SaleEventEnum;
import com.market.sale.application.ports.in.FinalizeSaleInputPort;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.kafka.annotation.KafkaListener;
import org.springframework.stereotype.Component;

@Slf4j
@RequiredArgsConstructor
@Component
public class ReceiveSaleToFinalizeConsumer {

  private final FinalizeSaleInputPort finalizeSaleInputPort;

  @KafkaListener(topics = "${application-config.kafka.topic}", groupId = "${application-config.kafka.consumer.group-id.finalize}")
  public void receive(SaleMessageDTO saleMessageDTO) {
    if(SaleEventEnum.VALIDATED_PAYMENT.equals(saleMessageDTO.getSaleEvent())) {
      log.info("Ending the sale...");
      this.finalizeSaleInputPort.finalize(saleMessageDTO.getSaleVO());
      log.info("Sale completed successfully.");
    }
  }
}
