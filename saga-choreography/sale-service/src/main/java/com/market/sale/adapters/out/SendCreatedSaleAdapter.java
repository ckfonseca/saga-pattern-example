package com.market.sale.adapters.out;

import com.market.sale.adapters.out.message.SaleMessage;
import com.market.sale.application.core.domain.Sale;
import com.market.sale.application.core.domain.enums.SaleEventEnum;
import com.market.sale.application.ports.out.SendCreatedSaleOutputPort;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Component
public class SendCreatedSaleAdapter implements SendCreatedSaleOutputPort {

  @Value("${application-config.kafka.topic}")
  private String topic;
  private final KafkaTemplate<String, SaleMessage> kafkaTemplate;

  @Override
  public void send(Sale sale, SaleEventEnum saleEvent) {
    var saleMessage = new SaleMessage(sale, saleEvent);
    this.kafkaTemplate.send(this.topic, saleMessage);
  }
}
