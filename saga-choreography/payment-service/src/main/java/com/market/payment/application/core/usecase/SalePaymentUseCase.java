package com.market.payment.application.core.usecase;

import com.market.payment.application.core.domain.Payment;
import com.market.payment.application.core.domain.Sale;
import com.market.payment.application.core.domain.enums.SaleEventEnum;
import com.market.payment.application.ports.in.FindUserByIdInputPort;
import com.market.payment.application.ports.in.SalePaymentInputPort;
import com.market.payment.application.ports.out.SavePaymentOutputPort;
import com.market.payment.application.ports.out.SendToKafkaOutputPort;
import com.market.payment.application.ports.out.UpdateUserOutputPort;
import lombok.extern.slf4j.Slf4j;

@Slf4j
public class SalePaymentUseCase implements SalePaymentInputPort {

    private final FindUserByIdInputPort findUserByIdInputPort;
    private final UpdateUserOutputPort updateUserOutputPort;
    private final SavePaymentOutputPort savePaymentOutputPort;
    private final SendToKafkaOutputPort sendToKafkaOutputPort;

    public SalePaymentUseCase(
            FindUserByIdInputPort findUserByIdInputPort,
            UpdateUserOutputPort updateUserOutputPort,
            SavePaymentOutputPort savePaymentOutputPort,
            SendToKafkaOutputPort sendToKafkaOutputPort
    ) {
        this.findUserByIdInputPort = findUserByIdInputPort;
        this.updateUserOutputPort = updateUserOutputPort;
        this.savePaymentOutputPort = savePaymentOutputPort;
        this.sendToKafkaOutputPort = sendToKafkaOutputPort;
    }

    @Override
    public void payment(Sale sale) {
        try {
            var user = this.findUserByIdInputPort.find(sale.getUserId());
            if(user.getBalance().compareTo(sale.getValue()) < 0) {
                throw new RuntimeException("Insufficient funds!");
            }
            user.debitBalance(sale.getValue());
            this.updateUserOutputPort.update(user);
            this.savePaymentOutputPort.save(this.buildPayment(sale));
            this.sendToKafkaOutputPort.send(sale, SaleEventEnum.VALIDATED_PAYMENT);
        } catch (Exception e) {
            log.error("An error occurred: {}", e.getMessage());
            this.sendToKafkaOutputPort.send(sale, SaleEventEnum.FAILED_PAYMENT);
        }
    }

    private Payment buildPayment(Sale sale) {
        return new Payment(null, sale.getUserId(), sale.getId(), sale.getValue());
    }
}
