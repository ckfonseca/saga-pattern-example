package com.market.sale.config.kafka;

import static org.apache.kafka.clients.consumer.ConsumerConfig.AUTO_OFFSET_RESET_CONFIG;
import static org.apache.kafka.clients.consumer.ConsumerConfig.BOOTSTRAP_SERVERS_CONFIG;
import static org.apache.kafka.clients.consumer.ConsumerConfig.KEY_DESERIALIZER_CLASS_CONFIG;
import static org.apache.kafka.clients.consumer.ConsumerConfig.VALUE_DESERIALIZER_CLASS_CONFIG;

import com.market.sale.adapters.out.message.SaleMessage;
import java.util.HashMap;
import java.util.Map;
import org.apache.kafka.common.serialization.StringDeserializer;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.kafka.annotation.EnableKafka;
import org.springframework.kafka.config.ConcurrentKafkaListenerContainerFactory;
import org.springframework.kafka.core.ConsumerFactory;
import org.springframework.kafka.core.DefaultKafkaConsumerFactory;

@EnableKafka
@Configuration
public class KafkaSaleConsumerConfig {

  @Value("${application-config.kafka.server-url}")
  private String serverUrl;

  @Value("${application-config.kafka.auto-offset-reset}")
  private String autoOffsetReset;

  @Bean
  public ConsumerFactory<String, SaleMessage> consumerFactory() {
    Map<String, Object> props = new HashMap<>();

    props.put(BOOTSTRAP_SERVERS_CONFIG, this.serverUrl);
    props.put(KEY_DESERIALIZER_CLASS_CONFIG, StringDeserializer.class);
    props.put(VALUE_DESERIALIZER_CLASS_CONFIG, CustomDeserializer.class);
    props.put(AUTO_OFFSET_RESET_CONFIG, this.autoOffsetReset);

    return new DefaultKafkaConsumerFactory<>(props);
  }

  @Bean
  public ConcurrentKafkaListenerContainerFactory<String, SaleMessage> kafkaListenerContainerFactory() {
    ConcurrentKafkaListenerContainerFactory<String, SaleMessage> factory = new ConcurrentKafkaListenerContainerFactory<>();
    factory.setConsumerFactory(consumerFactory());

    return factory;
  }
}
