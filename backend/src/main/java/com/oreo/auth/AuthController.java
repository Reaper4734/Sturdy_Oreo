package com.oreo.auth;

import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.tags.Tag;
import jakarta.validation.Valid;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/auth")
@Tag(name = "Authentication", description = "Register, Login, and Google OAuth2 Authentication")
public class AuthController {

    private final AuthService authService;
    private final UserRepository userRepository;

    public AuthController(AuthService authService, UserRepository userRepository) {
        this.authService = authService;
        this.userRepository = userRepository;
    }

    @PostMapping("/register")
    @Operation(summary = "Register with Email & Password")
    public ResponseEntity<AuthDto.AuthResponse> register(@Valid @RequestBody AuthDto.RegisterRequest req) {
        return ResponseEntity.ok(authService.register(req));
    }

    @PostMapping("/login")
    @Operation(summary = "Login with Email & Password")
    public ResponseEntity<AuthDto.AuthResponse> login(@Valid @RequestBody AuthDto.LoginRequest req) {
        return ResponseEntity.ok(authService.login(req));
    }

    @PostMapping("/google")
    @Operation(summary = "Authenticate with Google ID Token")
    public ResponseEntity<AuthDto.AuthResponse> googleAuth(@Valid @RequestBody AuthDto.GoogleAuthRequest req) {
        return ResponseEntity.ok(authService.authenticateGoogle(req));
    }

    @GetMapping("/profile")
    @Operation(summary = "Get current user profile stats")
    @io.swagger.v3.oas.annotations.security.SecurityRequirement(name = "bearerAuth")
    public ResponseEntity<AuthDto.UserProfileResponse> getProfile(org.springframework.security.core.Authentication authentication) {
        java.util.UUID userId = (java.util.UUID) authentication.getPrincipal();
        User user = userRepository.findById(userId).orElseThrow();
        // Ponytail Mode: Fetch user from DB, hardcode missing gamification fields for now
        return ResponseEntity.ok(new AuthDto.UserProfileResponse(
                userId,
                user.getDisplayName(),
                user.getEmail(),
                "Your Java backend is now connected to Flutter! Welcome " + user.getDisplayName() + ".",
                2,
                180,
                3
        ));
    }
}
