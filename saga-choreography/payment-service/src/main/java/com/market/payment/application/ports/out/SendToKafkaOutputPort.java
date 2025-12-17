package com.market.payment.application.ports.out;

import com.market.payment.application.core.domain.SaleVO;
import com.market.payment.application.core.domain.enums.SaleEventEnum;

public interface SendToKafkaOutputPort {

    void send(SaleVO saleVO, SaleEventEnum saleEvent);
}
