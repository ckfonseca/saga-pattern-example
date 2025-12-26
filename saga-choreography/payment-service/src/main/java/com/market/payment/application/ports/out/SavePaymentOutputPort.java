package com.market.payment.application.ports.out;

import com.market.payment.application.core.domain.Payment;

public interface SavePaymentOutputPort {

    void save(Payment payment);
}
