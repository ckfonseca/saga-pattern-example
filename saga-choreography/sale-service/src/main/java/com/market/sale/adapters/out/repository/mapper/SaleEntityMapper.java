package com.market.sale.adapters.out.repository.mapper;

import com.market.sale.adapters.out.repository.entity.SaleEntity;
import com.market.sale.application.core.domain.Sale;
import com.market.sale.application.core.domain.enums.SaleStatusEnum;
import org.mapstruct.Mapper;
import org.mapstruct.Mapping;
import org.mapstruct.Named;

@Mapper(componentModel = "spring")
public interface SaleEntityMapper {

  @Mapping(source = "saleStatus", target = "saleStatusId", qualifiedByName = "saleStatusToSaleStatusId")
  SaleEntity saleToSaleEntity(Sale sale);

  @Mapping(source = "saleStatusId", target = "saleStatus", qualifiedByName = "saleStatusIdToSaleStatus")
  Sale saleEntityToSale(SaleEntity saleEntity);

  @Named("saleStatusToSaleStatusId")
  default Integer saleStatusToSaleStatusId(SaleStatusEnum saleStatus) {

    return saleStatus.getId();
  }

  @Named("saleStatusIdToSaleStatus")
  default SaleStatusEnum saleStatusIdToSaleStatus(Integer saleStatusId) {

    return SaleStatusEnum.toEnum(saleStatusId);
  }
}
