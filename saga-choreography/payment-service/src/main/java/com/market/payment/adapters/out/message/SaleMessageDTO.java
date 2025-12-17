package com.market.payment.adapters.out.message;

import com.fasterxml.jackson.annotation.JsonProperty;
import com.market.payment.application.core.domain.SaleVO;
import com.market.payment.application.core.domain.enums.SaleEventEnum;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@NoArgsConstructor
@AllArgsConstructor
public class SaleMessageDTO {

    @JsonProperty("sale")
    private SaleVO saleVO;
    private SaleEventEnum saleEvent;
}
