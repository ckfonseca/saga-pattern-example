package com.market.payment.adapters.out;

import com.market.payment.adapters.out.repository.PaymentRepository;
import com.market.payment.adapters.out.repository.mapper.PaymentMapper;
import com.market.payment.application.core.domain.Payment;
import com.market.payment.application.ports.out.SavePaymentOutputPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Component
public class SavePaymentAdapter implements SavePaymentOutputPort {

    private final PaymentRepository paymentRepository;
    private final PaymentMapper paymentMapper;

    @Override
    public void save(Payment payment) {
        var paymentEntity = this.paymentMapper.paymentToPaymentEntity(payment);

        this.paymentRepository.save(paymentEntity);
    }
}
