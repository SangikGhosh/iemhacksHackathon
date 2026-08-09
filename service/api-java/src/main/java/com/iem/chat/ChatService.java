package com.iem.chat;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.iem.auth.UserRepository;
import com.iem.chat.dto.ChatHistoryResponse;
import com.iem.chat.dto.ChatRequest;
import com.iem.chat.dto.ChatResponse;
import com.iem.chat.dto.ConversationSummary;
import com.iem.enums.ChatAuthor;
import com.iem.exception.ApiException;
import com.iem.model.ChatMessage;
import com.iem.model.User;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.Instant;
import java.util.ArrayList;
import java.util.LinkedHashSet;
import java.util.List;
import java.util.UUID;

@Service
public class ChatService {

    private static final Logger log = LoggerFactory.getLogger(ChatService.class);

    private static final int MAX_TOOL_RESULT_CHARS = 6000;
    private static final int MAX_STORED_CONTENT = 4000;

    private final ObjectMapper mapper;
    private final LlmClient llm;
    private final ToolRegistry registry;
    private final ChatMessageRepository messageRepository;
    private final UserRepository userRepository;
    private final int historyTurns;
    private final int maxToolRounds;

    public ChatService(ObjectMapper mapper,
                       LlmClient llm,
                       ToolRegistry registry,
                       ChatMessageRepository messageRepository,
                       UserRepository userRepository,
                       @Value("${chat.history-turns:10}") int historyTurns,
                       @Value("${chat.max-tool-rounds:4}") int maxToolRounds) {
        this.mapper = mapper;
        this.llm = llm;
        this.registry = registry;
        this.messageRepository = messageRepository;
        this.userRepository = userRepository;
        this.historyTurns = historyTurns;
        this.maxToolRounds = maxToolRounds;
    }

    public ChatResponse ask(UUID userId, ChatRequest request) {

        User user = userRepository.findById(userId)
                .orElseThrow(() -> new ApiException("User not found", 404));

        UUID conversationId = request.getConversationId();
        if (conversationId != null
                && !messageRepository.existsByConversationIdAndUserId(conversationId, userId)) {
            throw new ApiException("Conversation not found", 404);
        }
        boolean newConversation = conversationId == null;
        if (newConversation) {
            conversationId = UUID.randomUUID();
        }

        ChatContext context = new ChatContext(user, request.getListingId(), request.getPickupId(),
                request.getLatitude(), request.getLongitude());

        ArrayNode messages = mapper.createArrayNode();
        messages.add(message("system", SystemPrompts.forUser(user) + screenContext(request)));

        List<ChatMessage> history = messageRepository.recent(conversationId, userId,
                PageRequest.of(0, Math.max(historyTurns, 1) * 2));

        for (int i = history.size() - 1; i >= 0; i--) {
            ChatMessage m = history.get(i);
            messages.add(message(m.getAuthor() == ChatAuthor.USER ? "user" : "assistant",
                    m.getContent()));
        }

        String question = request.getMessage().trim();
        messages.add(message("user", question));

        ArrayNode tools = registry.schemaFor(user.getRole());
        LinkedHashSet<String> used = new LinkedHashSet<>();
        String answer = null;

        for (int round = 0; round <= maxToolRounds; round++) {

            boolean lastRound = round == maxToolRounds;
            JsonNode reply = llm.complete(messages, lastRound ? null : tools);

            JsonNode toolCalls = reply.path("tool_calls");
            if (lastRound || !toolCalls.isArray() || toolCalls.isEmpty()) {
                answer = reply.path("content").asText("").trim();
                break;
            }

            messages.add(reply.deepCopy());

            for (JsonNode call : toolCalls) {
                String name = call.path("function").path("name").asText("");
                String rawArgs = call.path("function").path("arguments").asText("{}");
                String callId = call.path("id").asText("");

                used.add(name);
                messages.add(toolResult(callId, name, invoke(context, name, rawArgs)));
            }
        }

        if (answer == null || answer.isBlank()) {
            answer = "I could not put together an answer for that. Try rephrasing the question.";
        }

        String title = newConversation ? truncate(question, 110) : null;

        ChatMessage stored = new ChatMessage();
        stored.setConversationId(conversationId);
        stored.setUserId(userId);
        stored.setAuthor(ChatAuthor.USER);
        stored.setContent(truncate(question, MAX_STORED_CONTENT));
        stored.setTitle(title);

        ChatMessage assistant = new ChatMessage();
        assistant.setConversationId(conversationId);
        assistant.setUserId(userId);
        assistant.setAuthor(ChatAuthor.ASSISTANT);
        assistant.setContent(truncate(answer, MAX_STORED_CONTENT));
        assistant.setToolsUsed(used.isEmpty() ? null : truncate(String.join(",", used), 300));
        assistant.setTitle(title);

        messageRepository.saveAll(List.of(stored, assistant));

        return new ChatResponse(conversationId, answer, List.copyOf(used), history.size() + 2);
    }

    private String invoke(ChatContext context, String name, String rawArgs) {

        ChatTool tool = registry.resolve(context.role(), name);
        if (tool == null) {
            log.warn("{} requested unavailable tool {}", context.role(), name);
            return "{\"error\":\"That tool is not available for this account\"}";
        }

        JsonNode args;
        try {
            args = rawArgs == null || rawArgs.isBlank()
                    ? mapper.createObjectNode()
                    : mapper.readTree(rawArgs);
        } catch (JsonProcessingException e) {
            return "{\"error\":\"The tool arguments were not valid JSON\"}";
        }

        long started = System.currentTimeMillis();
        try {
            Object result = tool.execute(context, args);
            String json = mapper.writeValueAsString(result);
            log.debug("Tool {} for {} took {} ms", name, context.userId(),
                    System.currentTimeMillis() - started);
            return truncate(json, MAX_TOOL_RESULT_CHARS);

        } catch (ApiException e) {
            return "{\"error\":" + quote(e.getMessage()) + "}";
        } catch (Exception e) {
            log.error("Tool {} failed", name, e);
            return "{\"error\":\"That lookup failed\"}";
        }
    }

    @Transactional(readOnly = true)
    public ChatHistoryResponse history(UUID userId, UUID conversationId) {
        List<ChatMessage> items =
                messageRepository.findByConversationIdAndUserIdOrderByCreatedAtAsc(conversationId, userId);
        if (items.isEmpty()) {
            throw new ApiException("Conversation not found", 404);
        }
        return new ChatHistoryResponse(conversationId,
                items.stream().map(ChatHistoryResponse.Item::from).toList());
    }

    @Transactional(readOnly = true)
    public List<ConversationSummary> conversations(UUID userId, int limit) {
        List<ConversationSummary> out = new ArrayList<>();
        for (Object[] row : messageRepository.conversations(userId,
                PageRequest.of(0, Math.min(Math.max(limit, 1), 50)))) {
            out.add(new ConversationSummary(
                    (UUID) row[0],
                    row[1] == null ? "Conversation" : (String) row[1],
                    (Instant) row[2],
                    ((Number) row[3]).longValue()));
        }
        return out;
    }

    @Transactional
    public void delete(UUID userId, UUID conversationId) {
        if (messageRepository.deleteConversation(conversationId, userId) == 0) {
            throw new ApiException("Conversation not found", 404);
        }
    }

    public boolean isEnabled() {
        return llm.isConfigured();
    }

    public int toolCount() {
        return registry.size();
    }

    private static String screenContext(ChatRequest request) {
        StringBuilder context = new StringBuilder();

        if (request.getListingId() != null) {
            context.append("\nThe user has marketplace listing ")
                    .append(request.getListingId())
                    .append(" open on screen right now. Words like \"this\", \"this listing\", ")
                    .append("\"this deal\" or \"it\" refer to that listing. Call evaluate_listing ")
                    .append("without a listing_id to assess it. Never ask them which listing ")
                    .append("they mean.");
        }
        if (request.getPickupId() != null) {
            context.append("\nThe user has pickup ")
                    .append(request.getPickupId())
                    .append(" open on screen right now. \"This pickup\" refers to that one.");
        }
        if (request.getLatitude() != null && request.getLongitude() != null) {
            context.append("\nThe app has already shared the user's location, so call ")
                    .append("find_nearest_collection_points without coordinates. ")
                    .append("Never ask them for their latitude or longitude.");
        }

        return context.toString();
    }

    private ObjectNode message(String role, String content) {
        ObjectNode node = mapper.createObjectNode();
        node.put("role", role);
        node.put("content", content);
        return node;
    }

    private ObjectNode toolResult(String callId, String name, String content) {
        ObjectNode node = mapper.createObjectNode();
        node.put("role", "tool");
        node.put("tool_call_id", callId);
        node.put("name", name);
        node.put("content", content);
        return node;
    }

    private String quote(String value) {
        try {
            return mapper.writeValueAsString(value == null ? "" : value);
        } catch (JsonProcessingException e) {
            return "\"error\"";
        }
    }

    private static String truncate(String value, int max) {
        if (value == null) {
            return "";
        }
        return value.length() <= max ? value : value.substring(0, max);
    }
}
