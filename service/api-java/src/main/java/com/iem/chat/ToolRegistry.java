package com.iem.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import com.iem.enums.Role;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;

import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

@Component
public class ToolRegistry {

    private static final Logger log = LoggerFactory.getLogger(ToolRegistry.class);

    private final ObjectMapper mapper;
    private final Map<String, ChatTool> byName = new LinkedHashMap<>();

    public ToolRegistry(ObjectMapper mapper, List<ToolSet> toolSets) {
        this.mapper = mapper;
        for (ToolSet set : toolSets) {
            for (ChatTool tool : set.tools()) {
                ChatTool clash = byName.putIfAbsent(tool.name(), tool);
                if (clash != null) {
                    throw new IllegalStateException("Duplicate chat tool name: " + tool.name());
                }
            }
        }
        log.info("Registered {} chat tools", byName.size());
    }

    public List<ChatTool> forRole(Role role) {
        return byName.values().stream().filter(t -> t.roles().contains(role)).toList();
    }

    public ChatTool resolve(Role role, String name) {
        ChatTool tool = byName.get(name);
        if (tool == null || !tool.roles().contains(role)) {
            return null;
        }
        return tool;
    }

    public ArrayNode schemaFor(Role role) {
        ArrayNode tools = mapper.createArrayNode();
        for (ChatTool tool : forRole(role)) {
            ObjectNode function = mapper.createObjectNode();
            function.put("name", tool.name());
            function.put("description", tool.description());
            function.set("parameters", tool.parameters());

            ObjectNode entry = mapper.createObjectNode();
            entry.put("type", "function");
            entry.set("function", function);
            tools.add(entry);
        }
        return tools;
    }

    public int size() {
        return byName.size();
    }
}
