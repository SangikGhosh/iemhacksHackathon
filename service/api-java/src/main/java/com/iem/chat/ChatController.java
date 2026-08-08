package com.iem.chat;

import com.iem.chat.dto.ChatHistoryResponse;
import com.iem.chat.dto.ChatRequest;
import com.iem.chat.dto.ChatResponse;
import com.iem.chat.dto.ConversationSummary;
import com.iem.security.UserPrincipal;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/v1/chat")
public class ChatController {

    private final ChatService chatService;
    private final ToolRegistry registry;

    public ChatController(ChatService chatService, ToolRegistry registry) {
        this.chatService = chatService;
        this.registry = registry;
    }

    @PostMapping
    public ResponseEntity<ChatResponse> ask(@AuthenticationPrincipal UserPrincipal principal,
                                            @Valid @RequestBody ChatRequest request) {
        return ResponseEntity.ok(chatService.ask(principal.getId(), request));
    }

    @GetMapping("/conversations")
    public ResponseEntity<List<ConversationSummary>> conversations(
            @AuthenticationPrincipal UserPrincipal principal,
            @RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(chatService.conversations(principal.getId(), limit));
    }

    @GetMapping("/conversations/{id}")
    public ResponseEntity<ChatHistoryResponse> history(@AuthenticationPrincipal UserPrincipal principal,
                                                       @PathVariable UUID id) {
        return ResponseEntity.ok(chatService.history(principal.getId(), id));
    }

    @DeleteMapping("/conversations/{id}")
    public ResponseEntity<Map<String, Object>> delete(@AuthenticationPrincipal UserPrincipal principal,
                                                      @PathVariable UUID id) {
        chatService.delete(principal.getId(), id);
        return ResponseEntity.ok(Map.of("deleted", true));
    }

    @GetMapping("/capabilities")
    public ResponseEntity<Map<String, Object>> capabilities(
            @AuthenticationPrincipal UserPrincipal principal) {

        List<Map<String, String>> tools = registry.forRole(principal.getRole()).stream()
                .map(t -> Map.of("name", t.name(), "description", t.description()))
                .toList();

        Map<String, Object> body = new LinkedHashMap<>();
        body.put("enabled", chatService.isEnabled());
        body.put("role", principal.getRole().name());
        body.put("tools", tools);
        body.put("suggestions", Suggestions.forRole(principal.getRole()));
        return ResponseEntity.ok(body);
    }
}
