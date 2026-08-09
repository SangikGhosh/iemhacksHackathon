package com.iem.chat.dto;

import java.util.List;
import java.util.UUID;

public record ChatResponse(UUID conversationId,
                           String reply,
                           List<String> toolsUsed,
                           int historyLength) {
}
