package com.market.payment.application.ports.in;

import com.market.payment.application.core.domain.Sale;

public interface SalePaymentInputPort {

    void payment(Sale sale);
}
