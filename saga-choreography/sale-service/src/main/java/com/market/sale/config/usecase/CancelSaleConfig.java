package com.market.sale.config.usecase;

import com.market.sale.adapters.out.SaveSaleAdapter;
import com.market.sale.application.core.usecase.CancelSaleUseCase;
import com.market.sale.application.core.usecase.FindSaleByIdUseCase;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CancelSaleConfig {

  @Bean
  public CancelSaleUseCase cancelSaleUseCase(
      FindSaleByIdUseCase findSaleByIdUseCase,
      SaveSaleAdapter saveSaleAdapter
  ) {
    return new CancelSaleUseCase(findSaleByIdUseCase, saveSaleAdapter);
  }
}
