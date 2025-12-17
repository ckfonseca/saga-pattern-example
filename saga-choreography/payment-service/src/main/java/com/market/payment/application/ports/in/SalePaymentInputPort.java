package com.market.payment.application.ports.in;

import com.market.payment.application.core.domain.SaleVO;

public interface SalePaymentInputPort {

    void payment(SaleVO saleVO);
}
