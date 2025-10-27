package com.market.payment.application.ports.out;

import com.market.payment.application.core.domain.User;

public interface UpdateUserOutputPort {

    void update(User user);
}
