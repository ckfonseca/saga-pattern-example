package com.market.sale.adapters.out.repository.mapper;

import com.market.sale.adapters.out.repository.entity.SaleEntity;
import com.market.sale.application.core.domain.SaleVO;
import com.market.sale.application.core.domain.enums.SaleStatusEnum;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface SaleEntityMapper {

  @Mapping(source = "saleStatus", target = "saleStatusId", qualifiedByName = "saleStatusToSaleStatusId")
  SaleEntity saleVOToSaleEntity(SaleVO saleVO);

  @Mapping(source = "saleStatusId", target = "saleStatus", qualifiedByName = "saleStatusIdToSaleStatus")
  SaleVO saleEntityToSaleVO(SaleEntity saleEntity);

  @Named("saleStatusToSaleStatusId")
  default Integer saleStatusToSaleStatusId(SaleStatusEnum saleStatus) {

    return saleStatus.getId();
  }

  @Named("saleStatusIdToSaleStatus")
  default SaleStatusEnum saleStatusIdToSaleStatus(Integer saleStatusId) {

    return SaleStatusEnum.findById(saleStatusId);
  }
}
