package com.market.sale.config.kafka;

import static java.nio.charset.StandardCharsets.UTF_8;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.market.sale.adapters.out.message.SaleMessageDTO;
import org.apache.kafka.common.errors.SerializationException;
import org.apache.kafka.common.serialization.Deserializer;

public class CustomDeserializer implements Deserializer<SaleMessageDTO> {

  private final ObjectMapper objectMapper = new ObjectMapper();

  @Override
  public SaleMessageDTO deserialize(String topic, byte[] data) {
    this.objectMapper.registerModule(new JavaTimeModule());
    try {
      if (data == null || data.length == 0) {
        return null;
      }
      var src = new String(data, UTF_8);
      return this.objectMapper.readValue(src, SaleMessageDTO.class);
    } catch (Exception e) {
      throw new SerializationException(
          "Error deserializing byte[] to SaleMessage in sale microsservice");
    }
  }
}
