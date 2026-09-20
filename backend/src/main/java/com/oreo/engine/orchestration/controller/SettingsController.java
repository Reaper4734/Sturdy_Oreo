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

    private java.util.UUID resolveUserId(org.springframework.security.core.Authentication authentication) {
        if (authentication == null || authentication.getPrincipal() == null) {
            return java.util.UUID.fromString("00000000-0000-0000-0000-000000000001");
        }
        String p = authentication.getPrincipal().toString();
        if (p.isBlank() || "anonymousUser".equalsIgnoreCase(p)) {
            return java.util.UUID.fromString("00000000-0000-0000-0000-000000000001");
        }
        try {
            return java.util.UUID.fromString(p);
        } catch (IllegalArgumentException e) {
            return java.util.UUID.nameUUIDFromBytes(p.getBytes(java.nio.charset.StandardCharsets.UTF_8));
        }
    }

    @GetMapping("/profile")
    public ResponseEntity<Map<String, Object>> getProfileSettings(org.springframework.security.core.Authentication authentication) {
        java.util.UUID userId = resolveUserId(authentication);
        Optional<User> userOpt = userRepository.findById(userId);
        User user;
        if (userOpt.isEmpty()) {
            user = new User();
            user.setId(userId);
            user.setDisplayName("User");
            user.setEmail("user@oreo.local");
            try {
                user = userRepository.save(user);
            } catch (Exception ignored) {}
        } else {
            user = userOpt.get();
        }
        
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
        
        java.util.UUID userId = resolveUserId(authentication);
        Optional<User> userOpt = userRepository.findById(userId);
        User user;
        if (userOpt.isEmpty()) {
            user = new User();
            user.setId(userId);
            user.setDisplayName("User");
            user.setEmail("user@oreo.local");
        } else {
            user = userOpt.get();
        }
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
