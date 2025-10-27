package com.market.payment.application.core.usecase;

import com.market.payment.application.core.domain.User;
import com.market.payment.application.ports.in.FindUserByIdInputPort;
import com.market.payment.application.ports.out.FindUserByIdOutputPort;

public class FindUserByIdUseCase implements FindUserByIdInputPort {

    private final FindUserByIdOutputPort findUserByIdOutputPort;

    public FindUserByIdUseCase(FindUserByIdOutputPort findUserByIdOutputPort) {
        this.findUserByIdOutputPort = findUserByIdOutputPort;
    }

    @Override
    public User find(final Long id) {
        return this.findUserByIdOutputPort.find(id).orElseThrow(
                () -> new RuntimeException("User not found.")
        );
    }
}
