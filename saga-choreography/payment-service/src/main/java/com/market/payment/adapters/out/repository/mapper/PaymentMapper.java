package com.market.payment.adapters.out.repository.mapper;

import com.market.payment.adapters.out.repository.entity.PaymentEntity;
import com.market.payment.application.core.domain.Payment;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface PaymentMapper {

    PaymentEntity paymentToPaymentEntity(Payment payment);
}
