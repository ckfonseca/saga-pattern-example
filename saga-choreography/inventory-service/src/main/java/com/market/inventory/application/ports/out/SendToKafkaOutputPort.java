package com.market.inventory.application.ports.out;

import com.market.inventory.application.core.domain.Sale;
import com.market.inventory.application.core.domain.enums.SaleEventEnum;

public interface SendToKafkaOutputPort {

    void send(Sale sale, SaleEventEnum event);
}
