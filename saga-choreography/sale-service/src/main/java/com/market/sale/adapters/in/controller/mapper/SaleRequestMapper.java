package com.market.sale.adapters.in.controller.mapper;

import com.market.sale.adapters.in.controller.dto.SaleRequestDTO;
import com.market.sale.application.core.domain.Sale;
import org.mapstruct.Mapper;

@Mapper(componentModel = "spring")
public interface SaleRequestMapper {

  Sale saleRequestDTOToSale(SaleRequestDTO saleRequestDTO);
}
