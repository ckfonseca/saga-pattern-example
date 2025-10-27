package com.market.payment.adapters.out;

import com.market.payment.adapters.out.message.SaleMessage;
import com.market.payment.application.core.domain.Sale;
import com.market.payment.application.core.domain.enums.SaleEventEnum;
import com.market.payment.application.ports.out.SendToKafkaOutputPort;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Component
public class SendToKafkaAdapter implements SendToKafkaOutputPort {

    @Value("${application-config.kafka.topic}")
    private String topic;
    private final KafkaTemplate<String, SaleMessage> kafkaTemplate;

    @Override
    public void send(Sale sale, SaleEventEnum event) {
        var saleMessage = new SaleMessage(sale, event);
        this.kafkaTemplate.send(this.topic, saleMessage);
    }
}
