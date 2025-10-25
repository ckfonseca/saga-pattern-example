package com.market.sale.config.kafka;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.market.sale.adapters.out.message.SaleMessage;
import org.apache.kafka.common.errors.SerializationException;
import org.apache.kafka.common.serialization.Serializer;

public class CustomSerializer implements Serializer<SaleMessage> {

  private final ObjectMapper objectMapper = new ObjectMapper();

  @Override
  public byte[] serialize(String s, SaleMessage saleMessage) {
    try {
      if (saleMessage == null) {
        return null;
      }
      return this.objectMapper.writeValueAsBytes(saleMessage);
    } catch (Exception e) {
      throw new SerializationException("Error when serializing SaleMessage to byte[]");
    }
  }
}
