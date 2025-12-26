package com.market.payment.adapters.out;

import com.market.payment.adapters.out.repository.UserRepository;
import com.market.payment.adapters.out.repository.mapper.UserEntityMapper;
import com.market.payment.application.core.domain.User;
import com.market.payment.application.ports.out.FindUserByIdOutputPort;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.Optional;

@RequiredArgsConstructor
@Component
public class FindUserByIdAdapter implements FindUserByIdOutputPort {

    private final UserRepository userRepository;
    private final UserEntityMapper userEntityMapper;

    @Override
    public Optional<User> find(Long userId) {
        var userEntity = this.userRepository.findById(userId);

        return userEntity.map(this.userEntityMapper::userEntityToUser);
    }
}
