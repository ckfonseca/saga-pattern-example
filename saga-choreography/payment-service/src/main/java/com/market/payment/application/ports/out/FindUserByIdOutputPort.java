package com.market.payment.application.ports.out;

import com.market.payment.application.core.domain.UserVO;

import java.util.Optional;

public interface FindUserByIdOutputPort {

    Optional<UserVO> find(Long userId);
}
