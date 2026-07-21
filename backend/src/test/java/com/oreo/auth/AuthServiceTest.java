package com.oreo.auth;

import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.extension.ExtendWith;
import org.mockito.Mock;
import org.mockito.junit.jupiter.MockitoExtension;
import org.springframework.security.crypto.password.PasswordEncoder;

import java.util.Optional;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.*;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.*;

@ExtendWith(MockitoExtension.class)
class AuthServiceTest {

    @Mock private UserRepository userRepository;
    @Mock private PasswordEncoder passwordEncoder;
    @Mock private JwtService jwtService;

    private AuthService authService;

    @BeforeEach
    void setUp() {
        authService = new AuthService(userRepository, passwordEncoder, jwtService, "test-client-id");
    }

    @Test
    void shouldRegisterNewUser_whenEmailIsAvailable() {
        AuthDto.RegisterRequest req = new AuthDto.RegisterRequest("test@example.com", "secret123", "Test Student");
        when(userRepository.existsByEmail("test@example.com")).thenReturn(false);
        when(passwordEncoder.encode("secret123")).thenReturn("encoded_pass");
        
        User savedUser = new User("test@example.com", "encoded_pass", "Test Student", "EMAIL");
        savedUser.setId(UUID.randomUUID());
        when(userRepository.save(any(User.class))).thenReturn(savedUser);
        when(jwtService.generateToken(any(), any())).thenReturn("mock.jwt.token");

        AuthDto.AuthResponse resp = authService.register(req);

        assertNotNull(resp);
        assertEquals("mock.jwt.token", resp.token());
        assertEquals("test@example.com", resp.email());
        assertEquals("EMAIL", resp.authProvider());
    }

    @Test
    void shouldThrowException_whenRegisteringDuplicateEmail() {
        AuthDto.RegisterRequest req = new AuthDto.RegisterRequest("existing@example.com", "secret123", "Student");
        when(userRepository.existsByEmail("existing@example.com")).thenReturn(true);

        assertThrows(IllegalArgumentException.class, () -> authService.register(req));
    }

    @Test
    void shouldLoginSuccessfully_whenCredentialsAreValid() {
        AuthDto.LoginRequest req = new AuthDto.LoginRequest("user@example.com", "password123");
        User user = new User("user@example.com", "encoded_pass", "Student", "EMAIL");
        user.setId(UUID.randomUUID());

        when(userRepository.findByEmail("user@example.com")).thenReturn(Optional.of(user));
        when(passwordEncoder.matches("password123", "encoded_pass")).thenReturn(true);
        when(jwtService.generateToken(user.getId(), user.getEmail())).thenReturn("valid.token");

        AuthDto.AuthResponse resp = authService.login(req);

        assertNotNull(resp);
        assertEquals("valid.token", resp.token());
    }
}
