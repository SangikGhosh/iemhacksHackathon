package com.iem.chat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.iem.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientResponseException;

import java.time.Duration;

@Component
public class LlmClient {

    private static final Logger log = LoggerFactory.getLogger(LlmClient.class);

    private final RestClient client;
    private final ObjectMapper mapper;
    private final String apiKey;
    private final String model;
    private final double temperature;
    private final int maxTokens;

    public LlmClient(ObjectMapper mapper,
                     @Value("${llm.api-key:}") String apiKey,
                     @Value("${llm.base-url:https://openrouter.ai/api/v1}") String baseUrl,
                     @Value("${llm.model:openai/gpt-4o-mini}") String model,
                     @Value("${llm.temperature:0.2}") double temperature,
                     @Value("${llm.max-tokens:900}") int maxTokens,
                     @Value("${llm.timeout-seconds:45}") long timeoutSeconds,
                     @Value("${llm.referer:https://greentech.local}") String referer,
                     @Value("${llm.title:GreenRoute}") String title) {

        this.mapper = mapper;
        this.apiKey = apiKey == null ? "" : apiKey.trim();
        this.model = model;
        this.temperature = temperature;
        this.maxTokens = maxTokens;

        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(10));
        factory.setReadTimeout(Duration.ofSeconds(timeoutSeconds));

        this.client = RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(factory)
                .defaultHeader("HTTP-Referer", referer)
                .defaultHeader("X-Title", title)
                .build();
    }

    public boolean isConfigured() {
        return !apiKey.isEmpty();
    }

    public String model() {
        return model;
    }

    public JsonNode complete(ArrayNode messages, ArrayNode tools) {

        if (!isConfigured()) {
            throw new ApiException("The assistant is not configured on this server", 503);
        }

        ObjectNode body = mapper.createObjectNode();
        body.put("model", model);
        body.put("temperature", temperature);
        body.put("max_tokens", maxTokens);
        body.set("messages", messages);

        if (tools != null && !tools.isEmpty()) {
            body.set("tools", tools);
            body.put("tool_choice", "auto");
        }

        JsonNode response;
        try {
            response = client.post()
                    .uri("/chat/completions")
                    .header("Authorization", "Bearer " + apiKey)
                    .contentType(MediaType.APPLICATION_JSON)
                    .body(body)
                    .retrieve()
                    .body(JsonNode.class);
        } catch (ResourceAccessException e) {
            log.error("LLM unreachable: {}", e.getMessage());
            throw new ApiException("The assistant is unreachable right now. Please try again.", 503);
        } catch (RestClientResponseException e) {
            log.error("LLM returned {}: {}", e.getStatusCode(), e.getResponseBodyAsString());
            if (e.getStatusCode().value() == 429) {
                throw new ApiException("The assistant is rate limited. Please try again shortly.", 429);
            }
            throw new ApiException("The assistant rejected the request", 502);
        }

        if (response == null || !response.hasNonNull("choices") || response.get("choices").isEmpty()) {
            String detail = response != null && response.hasNonNull("error")
                    ? response.get("error").path("message").asText("")
                    : "";
            log.error("LLM returned no choices. {}", detail);
            throw new ApiException("The assistant returned an empty response", 502);
        }

        return response.get("choices").get(0).path("message");
    }
}
