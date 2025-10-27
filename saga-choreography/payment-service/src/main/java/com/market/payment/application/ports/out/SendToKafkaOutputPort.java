package com.market.payment.application.ports.out;

import com.market.payment.application.core.domain.Sale;
import com.market.payment.application.core.domain.enums.SaleEventEnum;

public interface SendToKafkaOutputPort {

    void send(Sale sale, SaleEventEnum saleEvent);
}
