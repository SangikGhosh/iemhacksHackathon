package com.iem.chat.dto;

import java.time.Instant;
import java.util.UUID;

public record ConversationSummary(UUID conversationId,
                                  String title,
                                  Instant lastMessageAt,
                                  long messageCount) {
}
