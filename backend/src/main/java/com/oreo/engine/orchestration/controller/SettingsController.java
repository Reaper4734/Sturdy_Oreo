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
        String displayName = user.getDisplayName() != null ? user.getDisplayName() : "User";
        String email = user.getEmail() != null ? user.getEmail() : "";
        String avatarUrl = user.getPictureUrl() != null ? user.getPictureUrl() : "";
        String initials = (!displayName.isBlank() && !displayName.equals("User")) 
            ? displayName.substring(0, Math.min(2, displayName.length())).toUpperCase()
            : (!email.isBlank() ? email.substring(0, Math.min(2, email.length())).toUpperCase() : "U");
        String joinDate = user.getCreatedAt() != null
            ? user.getCreatedAt().format(java.time.format.DateTimeFormatter.ofPattern("MMMM yyyy", java.util.Locale.ENGLISH))
            : "Recent";

        Map<String, Object> userMap = new java.util.LinkedHashMap<>();
        userMap.put("displayName", displayName);
        userMap.put("email", email);
        userMap.put("avatarUrl", avatarUrl);
        userMap.put("avatarInitials", initials);
        userMap.put("joinDate", joinDate);
        userMap.put("isPremium", true);
        userMap.put("bio", user.getBio() != null ? user.getBio() : "");
        userMap.put("country", user.getCountry() != null ? user.getCountry() : "");
        userMap.put("preferredLearningStyle", user.getDomain() != null ? user.getDomain() : "Visual");
        userMap.put("dailyGoalMinutes", 60);

        return ResponseEntity.ok(Map.of(
            "user", userMap,
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

    @org.springframework.web.bind.annotation.PutMapping("/profile")
    public ResponseEntity<Map<String, Object>> updateProfileSettings(
            org.springframework.security.core.Authentication authentication,
            @org.springframework.web.bind.annotation.RequestBody Map<String, Object> payload) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return ResponseEntity.status(401).build();
        }
        java.util.UUID userId = java.util.UUID.fromString(authentication.getPrincipal().toString());
        Optional<User> userOpt = userRepository.findById(userId);

        if (userOpt.isEmpty()) {
            return ResponseEntity.notFound().build();
        }

        User user = userOpt.get();
        if (payload.containsKey("displayName")) {
            String newName = (String) payload.get("displayName");
            if (newName != null && !newName.isBlank()) {
                user.setDisplayName(newName.trim());
            }
        }
        if (payload.containsKey("bio")) {
            user.setBio((String) payload.get("bio"));
        }
        if (payload.containsKey("country")) {
            user.setCountry((String) payload.get("country"));
        }
        if (payload.containsKey("avatarUrl")) {
            user.setPictureUrl((String) payload.get("avatarUrl"));
        }
        if (payload.containsKey("domain")) {
            user.setDomain((String) payload.get("domain"));
        }

        userRepository.save(user);
        return getProfileSettings(authentication);
    }
}
