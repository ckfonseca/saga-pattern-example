package com.market.sale.adapters.in.controller.mapper;

import com.market.sale.adapters.in.controller.dto.SaleRequestDTO;
import com.market.sale.application.core.domain.SaleVO;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface SaleRequestMapper {

  SaleVO saleRequestDTOToSaleVO(SaleRequestDTO saleRequestDTO);
}
