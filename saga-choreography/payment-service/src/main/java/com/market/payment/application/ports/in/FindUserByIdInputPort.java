package com.market.payment.application.ports.in;

import com.market.payment.application.core.domain.UserVO;

public interface FindUserByIdInputPort {

    UserVO find(final Long id);
}
