package com.market.sale.config.usecase;

import com.market.sale.adapters.out.FindSaleByIdAdapter;
import com.market.sale.application.core.usecase.FindSaleByIdUseCase;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class FindSaleByIdConfig {

  @Bean
  public FindSaleByIdUseCase findSaleByIdUseCase(FindSaleByIdAdapter findSaleByIdAdapter) {

    return new FindSaleByIdUseCase(findSaleByIdAdapter);
  }
}
