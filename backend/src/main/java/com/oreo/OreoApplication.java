package com.oreo;

import org.springframework.boot.CommandLineRunner;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Bean;
import org.springframework.scheduling.annotation.EnableAsync;
import org.springframework.scheduling.annotation.EnableScheduling;

import com.oreo.auth.User;
import com.oreo.auth.UserRepository;

@SpringBootApplication
@EnableScheduling
@EnableCaching
@EnableAsync
public class OreoApplication {

    public static void main(String[] args) {
        SpringApplication.run(OreoApplication.class, args);
    }

    // No mock data seeder.
}
