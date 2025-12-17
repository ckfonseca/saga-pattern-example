package com.market.inventory.application.ports.out;

import com.market.inventory.application.core.domain.SaleVO;
import com.market.inventory.application.core.domain.enums.SaleEventEnum;

public interface SendToKafkaOutputPort {

    void send(SaleVO saleVO, SaleEventEnum event);
}
