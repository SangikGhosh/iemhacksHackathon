package com.iem.chat.dto;

import com.iem.enums.ChatAuthor;
import com.iem.model.ChatMessage;

import java.time.Instant;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;

public record ChatHistoryResponse(UUID conversationId, List<Item> items) {

    public record Item(UUID id,
                       ChatAuthor author,
                       String content,
                       List<String> toolsUsed,
                       Instant createdAt) {

        public static Item from(ChatMessage m) {
            List<String> tools = m.getToolsUsed() == null || m.getToolsUsed().isBlank()
                    ? List.of()
                    : Arrays.stream(m.getToolsUsed().split(",")).map(String::trim).toList();
            return new Item(m.getId(), m.getAuthor(), m.getContent(), tools, m.getCreatedAt());
        }
    }
}
