package com.iem.detection;

import com.iem.detection.dto.DetectionApiResponse;
import com.iem.exception.ApiException;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.ByteArrayResource;
import org.springframework.http.MediaType;
import org.springframework.http.client.SimpleClientHttpRequestFactory;
import org.springframework.stereotype.Component;
import org.springframework.util.LinkedMultiValueMap;
import org.springframework.util.MultiValueMap;
import org.springframework.web.client.ResourceAccessException;
import org.springframework.web.client.RestClient;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.Duration;

@Component
public class DetectionClient {

    private static final Logger log = LoggerFactory.getLogger(DetectionClient.class);

    private final RestClient client;

    public DetectionClient(@Value("${detection.base-url}") String baseUrl,
                           @Value("${detection.timeout-seconds:45}") long timeoutSeconds) {
        SimpleClientHttpRequestFactory factory = new SimpleClientHttpRequestFactory();
        factory.setConnectTimeout(Duration.ofSeconds(10));
        factory.setReadTimeout(Duration.ofSeconds(timeoutSeconds));

        this.client = RestClient.builder()
                .baseUrl(baseUrl)
                .requestFactory(factory)
                .build();
    }

    public DetectionApiResponse detect(MultipartFile image) {

        MultiValueMap<String, Object> body = new LinkedMultiValueMap<>();
        body.add("image", asResource(image));

        try {
            DetectionApiResponse response = client.post()
                    .uri("/api/v1/detect")
                    .contentType(MediaType.MULTIPART_FORM_DATA)
                    .body(body)
                    .retrieve()
                    .body(DetectionApiResponse.class);

            if (response == null) {
                throw new ApiException("Detection service returned an empty response", 502);
            }

            return response;

        } catch (ResourceAccessException e) {
            log.error("Detection service unreachable: {}", e.getMessage());
            throw new ApiException("Detection service is unavailable. Please try again.", 503);
        }
    }

    private ByteArrayResource asResource(MultipartFile image) {
        byte[] bytes;
        try {
            bytes = image.getBytes();
        } catch (IOException e) {
            throw new ApiException("Could not read the uploaded image", 400);
        }

        String filename = image.getOriginalFilename() == null ? "upload.jpg" : image.getOriginalFilename();

        return new ByteArrayResource(bytes) {
            @Override
            public String getFilename() {
                return filename;
            }
        };
    }
}
