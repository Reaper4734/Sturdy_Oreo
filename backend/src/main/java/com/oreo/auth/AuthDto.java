package com.oreo.auth;

import jakarta.validation.constraints.Email;
import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.Size;
import java.util.UUID;

public class AuthDto {

    public record RegisterRequest(
            @NotBlank @Email String email,
            @NotBlank @Size(min = 6, message = "Password must be at least 6 characters") String password,
            @NotBlank String displayName
    ) {}

    public record LoginRequest(
            @NotBlank @Email String email,
            @NotBlank String password
    ) {}

    public record GoogleAuthRequest(
            @NotBlank String idToken
    ) {}

    public record AuthResponse(
            String token,
            UUID userId,
            String displayName,
            String email,
            String authProvider
    ) {}

    public record SessionStateResponse(
            UUID userId,
            String phase,
            boolean trackAccepted,
            String currentNodeId
    ) {}

    public record UserProfileResponse(
            UUID userId,
            String displayName,
            String email,
            String greetingInsight,
            int level,
            int xp,
            int streakDays
    ) {}
}
