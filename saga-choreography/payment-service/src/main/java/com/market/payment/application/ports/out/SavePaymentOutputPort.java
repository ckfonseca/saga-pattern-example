package com.market.payment.application.ports.out;

import com.market.payment.application.core.domain.PaymentVO;

public interface SavePaymentOutputPort {

    void save(PaymentVO paymentVO);
}
