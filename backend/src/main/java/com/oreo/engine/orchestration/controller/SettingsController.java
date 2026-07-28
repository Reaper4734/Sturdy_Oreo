package com.oreo.engine.orchestration.controller;

import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import com.oreo.auth.User;
import com.oreo.auth.UserRepository;

import java.util.Map;
import java.util.Optional;

@RestController
@RequestMapping("/api/settings")
public class SettingsController {

    private final UserRepository userRepository;

    public SettingsController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/profile")
    public ResponseEntity<Map<String, Object>> getProfileSettings(org.springframework.security.core.Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).build();
        }
        java.util.UUID userId = java.util.UUID.fromString(authentication.getPrincipal().toString());
        Optional<User> userOpt = userRepository.findById(userId);
        
        if (userOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }
        
        User user = userOpt.get();
        String displayName = user.getDisplayName();
        String email = user.getEmail();
        return ResponseEntity.ok(Map.of(
            "user", Map.of(
                "displayName", displayName,
                "email", email,
                "avatarUrl", "",
                "joinDate", "August 2026",
                "isPremium", true,
                "preferredLearningStyle", "Visual",
                "dailyGoalMinutes", 60
            ),
            "settings", Map.of(
                "isDarkMode", true,
                "enableSoundEffects", true,
                "autoPlayVideos", false,
                "aiPersonality", "Socratic (Default)",
                "aiVerbosity", "Concise",
                "language", "en_US",
                "showSubtitles", true,
                "playbackSpeed", 1.25
            ),
            "notifications", Map.of(
                "pushEnabled", true,
                "emailEnabled", false,
                "dailyReminders", true,
                "newFeatures", true,
                "weeklyReport", false
            )
        ));
    }
}
