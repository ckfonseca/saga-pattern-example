package com.market.sale.application.ports.in;

import com.market.sale.application.core.domain.Sale;

public interface FinalizeSaleInputPort {

    void finalize(Sale sale);
}
