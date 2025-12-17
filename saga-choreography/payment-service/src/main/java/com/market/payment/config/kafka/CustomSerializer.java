package com.market.payment.config.kafka;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.market.payment.adapters.out.message.SaleMessageDTO;
import org.apache.kafka.common.errors.SerializationException;
import org.apache.kafka.common.serialization.Serializer;

public class CustomSerializer implements Serializer<SaleMessageDTO> {

  private final ObjectMapper objectMapper = new ObjectMapper();

  @Override
  public byte[] serialize(String s, SaleMessageDTO saleMessageDTO) {
    this.objectMapper.registerModule(new JavaTimeModule());
    this.objectMapper.disable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    try {
      if (saleMessageDTO == null) {
        return new byte[0];
      }
      return this.objectMapper.writeValueAsBytes(saleMessageDTO);
    } catch (Exception e) {
      throw new SerializationException("Error when serializing SaleMessage to byte[]");
    }
  }
}
