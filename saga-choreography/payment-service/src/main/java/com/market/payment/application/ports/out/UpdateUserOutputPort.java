package com.market.payment.application.ports.out;

import com.market.payment.application.core.domain.UserVO;

public interface UpdateUserOutputPort {

    void update(UserVO userVO);
}
