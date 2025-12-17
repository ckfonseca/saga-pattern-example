package com.market.payment.application.core.usecase;

import com.market.payment.application.core.domain.PaymentVO;
import com.market.payment.application.core.domain.SaleVO;
import com.market.payment.application.core.domain.enums.SaleEventEnum;
import com.market.payment.application.ports.in.FindUserByIdInputPort;
import com.market.payment.application.ports.in.SalePaymentInputPort;
import com.market.payment.application.ports.out.SavePaymentOutputPort;
import com.market.payment.application.ports.out.SendToKafkaOutputPort;
import com.market.payment.application.ports.out.UpdateUserOutputPort;
import java.time.LocalDateTime;
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
    public void payment(SaleVO saleVO) {
        try {
            var userVO = this.findUserByIdInputPort.find(saleVO.getUserId());
            if(userVO.getBalance().compareTo(saleVO.getValue()) < 0) {
                throw new RuntimeException("Insufficient funds!");
            }
            userVO.debitBalance(saleVO.getValue());
            this.updateUserOutputPort.update(userVO);
            this.savePaymentOutputPort.save(this.buildPayment(saleVO));
            this.sendToKafkaOutputPort.send(saleVO, SaleEventEnum.VALIDATED_PAYMENT);
        } catch (Exception e) {
            log.error("An error occurred: {}", e.getMessage());
            this.sendToKafkaOutputPort.send(saleVO, SaleEventEnum.FAILED_PAYMENT);
        }
    }

    private PaymentVO buildPayment(SaleVO saleVO) {
        return new PaymentVO(null, saleVO.getUserId(), saleVO.getId(), saleVO.getValue(), LocalDateTime.now());
    }
}
