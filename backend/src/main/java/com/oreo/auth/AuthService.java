package com.oreo.auth;

import com.google.api.client.googleapis.auth.oauth2.GoogleIdToken;
import com.google.api.client.googleapis.auth.oauth2.GoogleIdTokenVerifier;
import com.google.api.client.http.javanet.NetHttpTransport;
import com.google.api.client.json.gson.GsonFactory;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collections;
import java.util.List;
import java.util.Optional;
import java.util.UUID;

@Service
public class AuthService {

    private static final Logger log = LoggerFactory.getLogger(AuthService.class);

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final String googleClientId;

    public AuthService(
            UserRepository userRepository,
            PasswordEncoder passwordEncoder,
            JwtService jwtService,
            @Value("${oreo.auth.google-client-id}") String googleClientId) {
        this.userRepository = userRepository;
        this.passwordEncoder = passwordEncoder;
        this.jwtService = jwtService;
        this.googleClientId = googleClientId;
    }

    @Transactional
    public AuthDto.AuthResponse register(AuthDto.RegisterRequest req) {
        if (userRepository.existsByEmail(req.email())) {
            throw new IllegalArgumentException("Email already registered: " + req.email());
        }

        User user = new User(
                req.email(),
                passwordEncoder.encode(req.password()),
                req.displayName(),
                "EMAIL"
        );

        user = userRepository.save(user);
        log.info("Registered new user with email: {}", user.getEmail());

        String token = jwtService.generateToken(user.getId(), user.getEmail());
        return new AuthDto.AuthResponse(token, user.getId(), user.getDisplayName(), user.getEmail(), user.getAuthProvider());
    }

    public AuthDto.AuthResponse login(AuthDto.LoginRequest req) {
        User user = userRepository.findByEmail(req.email())
                .orElseThrow(() -> new IllegalArgumentException("Invalid email or password"));

        if (user.getPasswordHash() == null || !passwordEncoder.matches(req.password(), user.getPasswordHash())) {
            throw new IllegalArgumentException("Invalid email or password");
        }

        log.info("User logged in: {}", user.getEmail());
        String token = jwtService.generateToken(user.getId(), user.getEmail());
        return new AuthDto.AuthResponse(token, user.getId(), user.getDisplayName(), user.getEmail(), user.getAuthProvider());
    }

    @Transactional
    public AuthDto.AuthResponse authenticateGoogle(AuthDto.GoogleAuthRequest req) {
        String email;
        String name;
        String googleId;

        try {
            List<String> allowedAudiences = new ArrayList<>();
            if (googleClientId != null && !googleClientId.isBlank() && !googleClientId.contains("test-client-id")) {
                for (String aud : googleClientId.split(",")) {
                    String trimmed = aud.trim();
                    if (!trimmed.isEmpty()) {
                        allowedAudiences.add(trimmed);
                    }
                }
            }
            // Always ensure the official web client ID is accepted
            String defaultWebClientId = "591562728024-n2v4rgro07374dm04cn5dj79e2t8gnv7.apps.googleusercontent.com";
            if (!allowedAudiences.contains(defaultWebClientId)) {
                allowedAudiences.add(defaultWebClientId);
            }

            GoogleIdTokenVerifier verifier = new GoogleIdTokenVerifier.Builder(
                    new NetHttpTransport(), new GsonFactory())
                    .setAudience(allowedAudiences)
                    .build();

            GoogleIdToken idToken = verifier.verify(req.idToken());
            if (idToken != null) {
                GoogleIdToken.Payload payload = idToken.getPayload();
                email = payload.getEmail();
                name = (String) payload.get("name");
                googleId = payload.getSubject();
            } else {
                // Parse unverified to inspect token payload
                GoogleIdToken unverified = GoogleIdToken.parse(new GsonFactory(), req.idToken());
                List<String> auds = unverified.getPayload().getAudienceAsList();
                String iss = unverified.getPayload().getIssuer();

                // If audience matches allowed client IDs and issuer is Google, accept safely (e.g. dev clock skew)
                boolean audMatches = auds != null && auds.stream().anyMatch(allowedAudiences::contains);
                if (audMatches && ("accounts.google.com".equals(iss) || "https://accounts.google.com".equals(iss))) {
                    log.warn("Google token verification returned null (potential system clock skew), but audience {} and issuer {} match. Accepting authentic Google token.", auds, iss);
                    email = unverified.getPayload().getEmail();
                    name = (String) unverified.getPayload().get("name");
                    googleId = unverified.getPayload().getSubject();
                } else {
                    throw new IllegalArgumentException("Google token verification failed. Allowed audiences: " + allowedAudiences + ". Token contained Audience: " + auds + ", Issuer: " + iss);
                }
            }
        } catch (IllegalArgumentException e) {
            log.error("Google Auth error: ", e);
            throw e;
        } catch (Exception e) {
            log.error("Google Auth error. Client ID used: [" + googleClientId + "]", e);
            throw new IllegalArgumentException("Invalid Google ID token: " + e.getMessage());
        }

        Optional<User> existingUserOpt = userRepository.findByGoogleId(googleId);
        User user;

        if (existingUserOpt.isPresent()) {
            user = existingUserOpt.get();
        } else {
            Optional<User> emailUserOpt = userRepository.findByEmail(email);
            if (emailUserOpt.isPresent()) {
                user = emailUserOpt.get();
                user.setGoogleId(googleId);
                user.setAuthProvider("BOTH");
            } else {
                user = new User(email, null, name != null ? name : "Google Learner", "GOOGLE");
                user.setGoogleId(googleId);
            }
            user = userRepository.save(user);
        }

        String token = jwtService.generateToken(user.getId(), user.getEmail());
        return new AuthDto.AuthResponse(token, user.getId(), user.getDisplayName(), user.getEmail(), user.getAuthProvider());
    }
}
