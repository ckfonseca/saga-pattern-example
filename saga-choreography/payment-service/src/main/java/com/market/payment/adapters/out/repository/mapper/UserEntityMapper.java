package com.market.payment.adapters.out.repository.mapper;

import com.market.payment.adapters.out.repository.entity.UserEntity;
import com.market.payment.application.core.domain.UserVO;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface UserEntityMapper {

    UserVO userEntityToUserVO(UserEntity userEntity);
    UserEntity userVOToUserEntity(UserVO userVO);

}
