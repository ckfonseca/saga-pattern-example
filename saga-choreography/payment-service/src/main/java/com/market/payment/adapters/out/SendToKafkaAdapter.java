package com.market.payment.adapters.out;

import com.market.payment.adapters.out.message.SaleMessageDTO;
import com.market.payment.application.core.domain.SaleVO;
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
    private final KafkaTemplate<String, SaleMessageDTO> kafkaTemplate;

    @Override
    public void send(SaleVO saleVO, SaleEventEnum event) {
        var saleMessageDTO = new SaleMessageDTO(saleVO, event);
        this.kafkaTemplate.send(this.topic, saleVO.getId().toString(), saleMessageDTO);
    }
}
