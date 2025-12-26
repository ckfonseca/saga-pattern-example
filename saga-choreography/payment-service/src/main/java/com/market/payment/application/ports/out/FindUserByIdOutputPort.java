package com.market.payment.application.ports.out;

import com.market.payment.application.core.domain.User;

import java.util.Optional;

public interface FindUserByIdOutputPort {

    Optional<User> find(Long userId);
}
