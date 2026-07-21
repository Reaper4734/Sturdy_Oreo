package com.oreo.session;

import com.oreo.auth.AuthDto;
import com.oreo.auth.User;
import com.oreo.auth.UserRepository;
import io.swagger.v3.oas.annotations.Operation;
import io.swagger.v3.oas.annotations.security.SecurityRequirement;
import io.swagger.v3.oas.annotations.tags.Tag;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequestMapping("/api/session")
@Tag(name = "Session", description = "Current Session & Phase State")
@SecurityRequirement(name = "bearerAuth")
public class SessionController {

    private final UserRepository userRepository;

    public SessionController(UserRepository userRepository) {
        this.userRepository = userRepository;
    }

    @GetMapping("/state")
    @Operation(summary = "Get Current Phase & Session State")
    public ResponseEntity<AuthDto.SessionStateResponse> getSessionState(Authentication authentication) {
        UUID userId = (UUID) authentication.getPrincipal();
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("User not found: " + userId));

        boolean trackAccepted = "EXECUTION".equals(user.getCurrentPhase());
        String currentNodeId = "EXECUTION".equals(user.getCurrentPhase()) ? "node_1" : null;

        return ResponseEntity.ok(new AuthDto.SessionStateResponse(
                user.getId(),
                user.getCurrentPhase(),
                trackAccepted,
                currentNodeId
        ));
    }
}
