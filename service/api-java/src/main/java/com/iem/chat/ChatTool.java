package com.iem.chat;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.iem.enums.Role;

import java.util.Set;
import java.util.function.BiFunction;

public interface ChatTool {

    String name();

    String description();

    Set<Role> roles();

    ObjectNode parameters();

    Object execute(ChatContext context, JsonNode arguments);

    record Simple(String name,
                  String description,
                  Set<Role> roles,
                  ObjectNode parameters,
                  BiFunction<ChatContext, JsonNode, Object> handler) implements ChatTool {

        @Override
        public Object execute(ChatContext context, JsonNode arguments) {
            return handler.apply(context, arguments);
        }
    }
}
