package com.market.inventory.adapters.out.message;

import com.market.inventory.application.core.domain.Sale;
import com.market.inventory.application.core.domain.enums.SaleEventEnum;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleMessage {
    private Sale sale;
    private SaleEventEnum saleEvent;
}
