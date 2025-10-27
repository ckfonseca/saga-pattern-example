package com.market.payment.application.ports.in;

import com.market.payment.application.core.domain.User;

public interface FindUserByIdInputPort {

    User find(final Long id);
}
