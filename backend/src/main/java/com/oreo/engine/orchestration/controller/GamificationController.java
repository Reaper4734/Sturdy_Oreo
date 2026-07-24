package com.oreo.engine.orchestration.controller;

import com.oreo.auth.User;
import com.oreo.auth.UserRepository;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/api/orchestration/gamification")
public class GamificationController {

    private final UserRepository userRepository;

    public GamificationController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @PostMapping("/award")
    public ResponseEntity<Map<String, Object>> awardPoints(
            @AuthenticationPrincipal String userId,
            @RequestBody Map<String, Integer> payload) {
            
        int pointsToAward = payload.getOrDefault("points", 0);
        
        // Find the user from the JWT principal
        User user = userRepository.findById(UUID.fromString(userId))
                .orElseThrow(() -> new RuntimeException("User not found"));

        // 1. Award or Deduct Points (Never drop below 0)
        int newTotal = user.getTotalPoints() + pointsToAward;
        user.setTotalPoints(Math.max(0, newTotal));

        // 2. Calculate Streaks
        LocalDate today = LocalDate.now();
        LocalDate lastActive = user.getLastActiveDate();

        if (lastActive == null) {
            user.setCurrentStreak(1);
        } else if (lastActive.equals(today.minusDays(1))) {
            // They were active yesterday, bump streak
            user.setCurrentStreak(user.getCurrentStreak() + 1);
        } else if (lastActive.isBefore(today.minusDays(1))) {
            // They missed a day, reset streak
            user.setCurrentStreak(1);
        }
        // If lastActive == today, do nothing to the streak.

        user.setLastActiveDate(today);
        userRepository.save(user);

        return ResponseEntity.ok(Map.of(
                "totalPoints", user.getTotalPoints(),
                "currentStreak", user.getCurrentStreak(),
                "message", "Awarded " + pointsToAward + " points"
        ));
    }
}
