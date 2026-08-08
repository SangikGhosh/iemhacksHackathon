package com.iem.rewards;

import com.iem.auth.UserRepository;
import com.iem.enums.Role;
import com.iem.rewards.dto.LeaderboardResponse;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
public class LeaderboardService {

    private final LeaderboardRepository leaderboardRepository;
    private final UserRepository userRepository;

    public LeaderboardService(LeaderboardRepository leaderboardRepository,
                              UserRepository userRepository) {
        this.leaderboardRepository = leaderboardRepository;
        this.userRepository = userRepository;
    }

    @Transactional(readOnly = true)
    public LeaderboardResponse top(UUID viewerId, int limit) {

        int size = Math.min(Math.max(limit, 1), 100);

        List<Object[]> rows = leaderboardRepository.topByPoints(PageRequest.of(0, size));

        List<LeaderboardResponse.Entry> entries = new ArrayList<>();
        int rank = 1;
        for (Object[] row : rows) {
            entries.add(new LeaderboardResponse.Entry(
                    rank++,
                    String.valueOf(row[0]),
                    (String) row[1],
                    row[2] == null ? null : ((Role) row[2]).name(),
                    ((Number) row[3]).intValue(),
                    ((Number) row[4]).longValue(),
                    scale(row[5])));
        }

        return new LeaderboardResponse("ALL_TIME", entries, me(viewerId), totals());
    }

    private LeaderboardResponse.Me me(UUID viewerId) {
        if (viewerId == null) {
            return null;
        }
        return userRepository.findById(viewerId)
                .map(user -> {
                    long ahead = leaderboardRepository.countAhead(user.getPoints());
                    return new LeaderboardResponse.Me(
                            (int) ahead + 1,
                            user.getPoints(),
                            leaderboardRepository.completedFor(user.getId()),
                            ahead);
                })
                .orElse(null);
    }

    private LeaderboardResponse.Totals totals() {
        return new LeaderboardResponse.Totals(
                leaderboardRepository.countScoring(),
                leaderboardRepository.totalPoints(),
                scale(leaderboardRepository.totalWeightCollected()),
                leaderboardRepository.totalCompletedPickups());
    }

    private static BigDecimal scale(Object value) {
        BigDecimal decimal = value == null ? BigDecimal.ZERO : (BigDecimal) value;
        return decimal.setScale(3, java.math.RoundingMode.HALF_UP);
    }
}
