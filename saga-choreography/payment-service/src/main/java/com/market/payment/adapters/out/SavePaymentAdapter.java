package com.market.payment.adapters.out;

import com.market.payment.adapters.out.repository.PaymentRepository;
import com.market.payment.adapters.out.repository.mapper.PaymentMapper;
import com.market.payment.application.core.domain.PaymentVO;
import com.market.payment.application.ports.out.SavePaymentOutputPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Component
public class SavePaymentAdapter implements SavePaymentOutputPort {

    private final PaymentRepository paymentRepository;
    private final PaymentMapper paymentMapper;

    @Override
    public void save(PaymentVO paymentVO) {
        var paymentEntity = this.paymentMapper.paymentVOToPaymentEntity(paymentVO);

        this.paymentRepository.save(paymentEntity);
    }
}
