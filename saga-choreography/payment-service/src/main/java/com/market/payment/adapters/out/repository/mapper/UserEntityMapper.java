package com.market.payment.adapters.out.repository.mapper;

import com.market.payment.adapters.out.repository.entity.UserEntity;
import com.market.payment.application.core.domain.User;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface UserEntityMapper {

    User userEntityToUser(UserEntity userEntity);
    UserEntity userToUserEntity(User user);

}
