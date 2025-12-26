package com.market.inventory.config.kafka;

import static java.nio.charset.StandardCharsets.UTF_8;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import com.market.inventory.adapters.out.message.SaleMessage;
import org.apache.kafka.common.errors.SerializationException;
import org.apache.kafka.common.serialization.Deserializer;

public class CustomDeserializer implements Deserializer<SaleMessage> {

  private final ObjectMapper objectMapper = new ObjectMapper();

  @Override
  public SaleMessage deserialize(String topic, byte[] data) {
    this.objectMapper.registerModule(new JavaTimeModule());
    try {
      if (data == null || data.length == 0) {
        return null;
      }
      var src = new String(data, UTF_8);
      return this.objectMapper.readValue(src, SaleMessage.class);
    } catch (Exception e) {
      throw new SerializationException(
          "Error deserializing byte[] to SaleMessage in inventory microsservice");
    }
  }
}
