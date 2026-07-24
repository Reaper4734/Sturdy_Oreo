package com.oreo.config;

import com.oreo.auth.JwtService;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    private final JwtService jwtService;
    private final String allowedOrigins;

    public WebSocketConfig(
            JwtService jwtService,
            @org.springframework.beans.factory.annotation.Value("${oreo.cors.allowed-origins:*}") String allowedOrigins) {
        this.jwtService = jwtService;
        this.allowedOrigins = allowedOrigins;
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws/orchestration")
                .setAllowedOriginPatterns(allowedOrigins.split(","))
                .withSockJS(); // Fallback
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
        registration.interceptors(new org.springframework.messaging.support.ChannelInterceptor() {
            @Override
            public org.springframework.messaging.Message<?> preSend(org.springframework.messaging.Message<?> message, org.springframework.messaging.MessageChannel channel) {
                org.springframework.messaging.simp.stomp.StompHeaderAccessor accessor = org.springframework.messaging.simp.stomp.StompHeaderAccessor.wrap(message);
                if (org.springframework.messaging.simp.stomp.StompCommand.CONNECT.equals(accessor.getCommand())) {
                    java.util.List<String> authorization = accessor.getNativeHeader("Authorization");
                    if (authorization != null && !authorization.isEmpty()) {
                        String bearerToken = authorization.get(0);
                        if (org.springframework.util.StringUtils.hasText(bearerToken) && bearerToken.startsWith("Bearer ")) {
                            String jwt = bearerToken.substring(7);
                            if (jwtService.validateToken(jwt)) {
                                java.util.UUID userId = jwtService.getUserIdFromToken(jwt);
                                org.springframework.security.authentication.UsernamePasswordAuthenticationToken auth = 
                                    new org.springframework.security.authentication.UsernamePasswordAuthenticationToken(userId, null, java.util.Collections.emptyList());
                                accessor.setUser(auth);
                            }
                        }
                    }
                } else if (org.springframework.messaging.simp.stomp.StompCommand.SUBSCRIBE.equals(accessor.getCommand())) {
                    // Subscription Authorization Check
                    java.security.Principal user = accessor.getUser();
                    String destination = accessor.getDestination();
                    if (destination != null && destination.startsWith("/topic/session/user/")) {
                        String targetUserId = destination.replace("/topic/session/user/", "").split("/")[0];
                        if (user == null || !user.getName().equals(targetUserId)) {
                            throw new org.springframework.security.access.AccessDeniedException("Unauthorized WebSocket topic subscription");
                        }
                    }
                }
                return message;
            }
        });

        // Optimize for high-throughput live audio bytes from frontend -> backend
        registration.taskExecutor()
                .corePoolSize(10)
                .maxPoolSize(100)
                .keepAliveSeconds(60);
    }

    @Override
    public void configureClientOutboundChannel(ChannelRegistration registration) {
        // Optimize for high-throughput STOMP & audio bytes from backend -> frontend
        registration.taskExecutor()
                .corePoolSize(10)
                .maxPoolSize(100)
                .keepAliveSeconds(60);
    }
}
