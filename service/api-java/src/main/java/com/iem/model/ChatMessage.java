package com.iem.model;

import com.iem.enums.ChatAuthor;
import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Setter;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.time.Instant;
import java.util.UUID;

@Getter
@Setter
@Entity
@NoArgsConstructor
@Table(name = "chat_messages", indexes = {
        @Index(name = "idx_chat_conversation", columnList = "conversation_id, created_at"),
        @Index(name = "idx_chat_user", columnList = "user_id, created_at")
})
public class ChatMessage {

    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID id;

    @Column(name = "conversation_id", nullable = false)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID conversationId;

    @Column(name = "user_id", nullable = false)
    @JdbcTypeCode(SqlTypes.UUID)
    private UUID userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false, length = 12)
    private ChatAuthor author;

    @Column(nullable = false, length = 4000)
    private String content;

    @Column(length = 300)
    private String toolsUsed;

    @Column(length = 120)
    private String title;

    @Column(nullable = false, updatable = false)
    private Instant createdAt;

    @PrePersist
    void onCreate() {
        this.createdAt = Instant.now();
    }
}
