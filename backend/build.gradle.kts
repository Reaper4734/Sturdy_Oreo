plugins {
    java
    id("org.springframework.boot") version "3.4.2"
    id("io.spring.dependency-management") version "1.1.7"
    kotlin("jvm") version "1.9.25"
    jacoco
}

group = "com.oreo"
version = "0.0.1-SNAPSHOT"

java {
    toolchain {
        languageVersion.set(JavaLanguageVersion.of(21))
    }
}

jacoco {
    toolVersion = "0.8.11"
}

repositories {
    mavenCentral()
}

dependencies {
    // Lombok
    compileOnly("org.projectlombok:lombok")
    annotationProcessor("org.projectlombok:lombok")

    // Spring Boot Core Starters
    implementation("org.springframework.boot:spring-boot-starter-web")
    implementation("org.springframework.boot:spring-boot-starter-data-jpa")
    implementation("org.springframework.boot:spring-boot-starter-websocket")
    implementation("org.springframework.boot:spring-boot-starter-security")
    implementation("org.springframework.boot:spring-boot-starter-actuator")
    implementation("org.springframework.boot:spring-boot-starter-validation")

    // Swagger / OpenAPI 3 Documentation
    implementation("org.springdoc:springdoc-openapi-starter-webmvc-ui:2.8.0")

    // Database & Migrations
    implementation("org.flywaydb:flyway-core")
    implementation("org.flywaydb:flyway-database-postgresql")
    runtimeOnly("org.postgresql:postgresql")

    // JWT Auth
    implementation("io.jsonwebtoken:jjwt-api:0.12.6")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.6")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.6")

    // Google Auth ID Token Verifier
    implementation("com.google.api-client:google-api-client:2.7.0")

    // Kotlin reflect for Springdoc OpenAPI (fixed 500 error)
    implementation("org.jetbrains.kotlin:kotlin-reflect")

    // LangChain4j for AI Orchestration
    implementation("dev.langchain4j:langchain4j:0.36.2")
    implementation("dev.langchain4j:langchain4j-google-ai-gemini:0.36.2")
    implementation("dev.langchain4j:langchain4j-pgvector:0.36.2")
    implementation("dev.langchain4j:langchain4j-open-ai:0.36.2")
    implementation("dev.langchain4j:langchain4j-embeddings-all-minilm-l6-v2:0.36.2")

    // DJL Whisper & ONNX Runtime (Local processing)
    implementation("ai.djl:api:0.30.0")
    implementation("ai.djl.onnxruntime:onnxruntime-engine:0.30.0")

    // .env file loader
    implementation("me.paulschwarz:spring-dotenv:4.0.0")

    // Phase 1 Performance & Resilience
    implementation("org.springframework.boot:spring-boot-starter-data-redis")
    implementation("org.springframework.boot:spring-boot-starter-cache")
    implementation("io.github.resilience4j:resilience4j-spring-boot3:2.2.0")

    // Testing
    testImplementation("org.springframework.boot:spring-boot-starter-test")
    testImplementation("org.springframework.security:spring-security-test")
    testImplementation("org.testcontainers:postgresql:1.20.4")
    testImplementation("org.testcontainers:junit-jupiter:1.20.4")
}

tasks.withType<Test> {
    useJUnitPlatform()
}

tasks.test {
    useJUnitPlatform()
    finalizedBy(tasks.jacocoTestReport)
}

tasks.jacocoTestReport {
    dependsOn(tasks.test)
    reports {
        xml.required.set(true)
        html.required.set(true)
    }
}
