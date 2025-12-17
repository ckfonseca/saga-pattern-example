package com.market.payment.adapters.out;

import com.market.payment.adapters.out.repository.UserRepository;
import com.market.payment.adapters.out.repository.mapper.UserEntityMapper;
import com.market.payment.application.core.domain.UserVO;
import com.market.payment.application.ports.out.UpdateUserOutputPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

@RequiredArgsConstructor
@Component
public class UpdateUserAdapter implements UpdateUserOutputPort {

    private final UserRepository userRepository;
    private final UserEntityMapper userEntityMapper;

    @Override
    public void update(UserVO userVO) {
        var userEntity = this.userEntityMapper.userVOToUserEntity(userVO);

        this.userRepository.save(userEntity);
    }
}
