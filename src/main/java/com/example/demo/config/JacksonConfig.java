package com.example.demo.config;

import org.springframework.boot.jackson.autoconfigure.JsonMapperBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import tools.jackson.databind.module.SimpleModule;
import tools.jackson.databind.ser.std.ToStringSerializer;

import java.text.SimpleDateFormat;
import java.util.TimeZone;

/**
 * Jackson 3 全局配置。
 *
 * <p>通过 {@link JsonMapperBuilderCustomizer} 定制 Spring Boot 自动配置的
 * {@link tools.jackson.databind.json.JsonMapper}，避免暴露重复的
 * {@code @Primary} 导致启动冲突。</p>
 */
@Configuration
public class JacksonConfig {

    @Bean
    public JsonMapperBuilderCustomizer jacksonCustomizer() {
        return builder -> {
            var module = new SimpleModule();
            module.addSerializer(Long.class, ToStringSerializer.instance);
            module.addSerializer(Long.TYPE, ToStringSerializer.instance);

            builder.defaultTimeZone(TimeZone.getTimeZone("GMT+8"));
            builder.defaultDateFormat(new SimpleDateFormat("yyyy-MM-dd HH:mm:ss"));
            builder.addModule(module);
        };
    }
}
