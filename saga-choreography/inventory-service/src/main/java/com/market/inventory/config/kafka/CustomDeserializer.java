package com.market.inventory.config.kafka;

import static java.nio.charset.StandardCharsets.UTF_8;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.market.inventory.adapters.out.message.SaleMessage;
import java.nio.charset.StandardCharsets;
import org.apache.kafka.common.errors.SerializationException;
import org.apache.kafka.common.serialization.Deserializer;

public class CustomDeserializer implements Deserializer<SaleMessage> {

    private final ObjectMapper objectMapper = new ObjectMapper();

    @Override
    public SaleMessage deserialize(String topic, byte[] data) {
        try {
            if(data == null) {
                return null;
            }
            var src = new String(data, UTF_8);
            return this.objectMapper.readValue(src, SaleMessage.class);
        } catch (Exception e) {
            throw new SerializationException("Error when deserializing byte[] to SaleMessage");
        }
    }
}
