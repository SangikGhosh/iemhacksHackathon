package com.iem.rewards;

import com.iem.rewards.dto.LeaderboardResponse;
import com.iem.security.UserPrincipal;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/v1/leaderboard")
public class LeaderboardController {

    private final LeaderboardService leaderboardService;

    public LeaderboardController(LeaderboardService leaderboardService) {
        this.leaderboardService = leaderboardService;
    }

    @GetMapping
    public ResponseEntity<LeaderboardResponse> top(@AuthenticationPrincipal UserPrincipal principal,
                                                   @RequestParam(defaultValue = "20") int limit) {
        return ResponseEntity.ok(
                leaderboardService.top(principal == null ? null : principal.getId(), limit));
    }
}
