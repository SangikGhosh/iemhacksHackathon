package com.iem.chat;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.node.ArrayNode;
import com.fasterxml.jackson.databind.node.ObjectNode;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
public class ToolSchema {

    private final ObjectMapper mapper;

    public ToolSchema(ObjectMapper mapper) {
        this.mapper = mapper;
    }

    public ObjectNode empty() {
        ObjectNode node = mapper.createObjectNode();
        node.put("type", "object");
        node.set("properties", mapper.createObjectNode());
        node.set("required", mapper.createArrayNode());
        return node;
    }

    public Builder object() {
        return new Builder(mapper);
    }

    public static class Builder {

        private final ObjectMapper mapper;
        private final ObjectNode properties;
        private final ArrayNode required;

        Builder(ObjectMapper mapper) {
            this.mapper = mapper;
            this.properties = mapper.createObjectNode();
            this.required = mapper.createArrayNode();
        }

        public Builder string(String name, String description) {
            ObjectNode field = mapper.createObjectNode();
            field.put("type", "string");
            field.put("description", description);
            properties.set(name, field);
            return this;
        }

        public Builder enumeration(String name, String description, List<String> values) {
            ObjectNode field = mapper.createObjectNode();
            field.put("type", "string");
            field.put("description", description);
            ArrayNode allowed = mapper.createArrayNode();
            values.forEach(allowed::add);
            field.set("enum", allowed);
            properties.set(name, field);
            return this;
        }

        public Builder integer(String name, String description) {
            ObjectNode field = mapper.createObjectNode();
            field.put("type", "integer");
            field.put("description", description);
            properties.set(name, field);
            return this;
        }

        public Builder number(String name, String description) {
            ObjectNode field = mapper.createObjectNode();
            field.put("type", "number");
            field.put("description", description);
            properties.set(name, field);
            return this;
        }

        public Builder require(String... names) {
            for (String name : names) {
                required.add(name);
            }
            return this;
        }

        public ObjectNode build() {
            ObjectNode node = mapper.createObjectNode();
            node.put("type", "object");
            node.set("properties", properties);
            node.set("required", required);
            return node;
        }
    }
}
