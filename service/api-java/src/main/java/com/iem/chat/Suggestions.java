package com.iem.chat;

import com.iem.enums.Role;

import java.util.List;

public final class Suggestions {

    private Suggestions() {
    }

    public static List<String> forRole(Role role) {
        return switch (role) {
            case CITIZEN -> List.of(
                    "What is my rewards summary?",
                    "Show my payment history",
                    "What is a PET bottle worth per kg?",
                    "Where is the nearest collection point?",
                    "What happened to my last pickup?");
            case COLLECTOR -> List.of(
                    "What pickups can I accept right now?",
                    "What does my route look like today?",
                    "How much have I collected this month?",
                    "How close am I to vehicle capacity?");
            case RECYCLER -> List.of(
                    "Is this listing worth buying?",
                    "What cardboard is available to buy?",
                    "Show my purchase history",
                    "What is my wallet balance?");
            case MUNICIPAL_ADMIN -> List.of(
                    "How many pickups completed today?",
                    "Show the scan trend for the last 7 days",
                    "How much waste did we divert this month?",
                    "Break down materials by bin colour",
                    "Which collectors do I have?");
            case SUPER_ADMIN -> List.of(
                    "Total transactions today",
                    "Compare waste diverted by municipality",
                    "How many new users in the last 30 days?",
                    "What is the marketplace turnover this month?",
                    "Show the pickup trend for the last 7 days");
        };
    }
}
