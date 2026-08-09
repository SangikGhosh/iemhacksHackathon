package com.iem.chat;

import com.iem.model.ChatMessage;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface ChatMessageRepository extends JpaRepository<ChatMessage, UUID> {

    List<ChatMessage> findByConversationIdAndUserIdOrderByCreatedAtAsc(UUID conversationId, UUID userId);

    @Query("""
           select m from ChatMessage m
            where m.conversationId = :conversationId and m.userId = :userId
            order by m.createdAt desc
           """)
    List<ChatMessage> recent(@Param("conversationId") UUID conversationId,
                             @Param("userId") UUID userId,
                             Pageable pageable);

    @Query("""
           select m.conversationId, min(m.title), max(m.createdAt), count(m)
             from ChatMessage m
            where m.userId = :userId
            group by m.conversationId
            order by max(m.createdAt) desc
           """)
    List<Object[]> conversations(@Param("userId") UUID userId, Pageable pageable);

    boolean existsByConversationIdAndUserId(UUID conversationId, UUID userId);

    @Modifying
    @Query("delete from ChatMessage m where m.conversationId = :conversationId and m.userId = :userId")
    int deleteConversation(@Param("conversationId") UUID conversationId, @Param("userId") UUID userId);
}
