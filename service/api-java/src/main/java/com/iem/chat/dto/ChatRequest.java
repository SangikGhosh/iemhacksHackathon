package com.iem.chat.dto;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import lombok.Getter;
import lombok.Setter;

import java.util.UUID;

@Getter
@Setter
public class ChatRequest {

    @NotBlank(message = "message is required")
    @Size(max = 1000, message = "message must be 1000 characters or fewer")
    private String message;

    private UUID conversationId;

    private UUID listingId;

    private UUID pickupId;

    private Double latitude;

    private Double longitude;
}
