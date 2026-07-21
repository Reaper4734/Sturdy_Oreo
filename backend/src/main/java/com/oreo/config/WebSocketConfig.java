package com.oreo.config;

import com.oreo.engine.orchestration.controller.GeminiLiveProxyWebSocketHandler;
import org.springframework.context.annotation.Configuration;
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

    public WebSocketConfig(GeminiLiveProxyWebSocketHandler geminiLiveProxyWebSocketHandler) {
        this.geminiLiveProxyWebSocketHandler = geminiLiveProxyWebSocketHandler;
    }

    @Override
    public void configureMessageBroker(MessageBrokerRegistry config) {
        config.enableSimpleBroker("/topic", "/queue");
        config.setApplicationDestinationPrefixes("/app");
    }

    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws/orchestration")
                .setAllowedOriginPatterns("*")
                .withSockJS(); // Fallback
    }

    @Override
    public void registerWebSocketHandlers(WebSocketHandlerRegistry registry) {
        // Raw websocket proxy for Gemini Multimodal Live API (binary audio stream)
        registry.addHandler(geminiLiveProxyWebSocketHandler, "/ws/live")
                .setAllowedOriginPatterns("*");
    }
}
