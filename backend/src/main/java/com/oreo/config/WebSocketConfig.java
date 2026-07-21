package com.oreo.config;

import com.oreo.engine.orchestration.controller.GeminiLiveProxyWebSocketHandler;
import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.ChannelRegistration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocket;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketConfigurer;
import org.springframework.web.socket.config.annotation.WebSocketHandlerRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
@EnableWebSocket
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer, WebSocketConfigurer {

    private final GeminiLiveProxyWebSocketHandler geminiLiveProxyWebSocketHandler;
    private final String allowedOrigins;

    public WebSocketConfig(
            GeminiLiveProxyWebSocketHandler geminiLiveProxyWebSocketHandler,
            @org.springframework.beans.factory.annotation.Value("${oreo.cors.allowed-origins:*}") String allowedOrigins) {
        this.geminiLiveProxyWebSocketHandler = geminiLiveProxyWebSocketHandler;
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
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        // Raw websocket proxy for Gemini Multimodal Live API (binary audio stream)
        registry.addHandler(geminiLiveProxyWebSocketHandler, "/ws/live")
                .setAllowedOriginPatterns(allowedOrigins.split(","));
    }

    @Override
    public void configureClientInboundChannel(ChannelRegistration registration) {
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
