package com.market.sale.config.kafka;

import static org.apache.kafka.clients.consumer.ConsumerConfig.GROUP_ID_CONFIG;
import static org.apache.kafka.clients.producer.ProducerConfig.BOOTSTRAP_SERVERS_CONFIG;
import static org.apache.kafka.clients.producer.ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG;
import static org.apache.kafka.clients.producer.ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG;

import com.market.sale.adapters.out.message.SaleMessage;
import java.util.HashMap;
import java.util.Map;
import org.apache.kafka.common.serialization.StringSerializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.core.DefaultKafkaProducerFactory;
import org.springframework.kafka.core.KafkaTemplate;
import org.springframework.kafka.core.ProducerFactory;

@Configuration
public class KafkaSaleProducerConfig {

  @Value("${application-config.kafka.server-url}")
  private String serverUrl;
  @Value("${application-config.kafka.producer.group-id}")
  private String groupId;

  @Bean
  public ProducerFactory<String, SaleMessage> producerFactory() {
    Map<String, Object> configPropsMap = new HashMap<>();
    configPropsMap.put(BOOTSTRAP_SERVERS_CONFIG, this.serverUrl);
    configPropsMap.put(GROUP_ID_CONFIG, this.groupId);
    configPropsMap.put(KEY_SERIALIZER_CLASS_CONFIG, StringSerializer.class);
    configPropsMap.put(VALUE_SERIALIZER_CLASS_CONFIG, CustomSerializer.class);

    return new DefaultKafkaProducerFactory<>(configPropsMap);
  }

  @Bean
  public KafkaTemplate<String, SaleMessage> kafkaTemplate() {

    return new KafkaTemplate<>(this.producerFactory());
  }
}
