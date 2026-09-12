plugins {
    java
    id("org.springframework.boot") version "3.4.2"
    id("io.spring.dependency-management") version "1.1.7"
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
    implementation("org.postgresql:postgresql")

    // Google API Client for validating Google Sign-In ID Tokens
    implementation("com.google.api-client:google-api-client:2.7.0")

    // JWT Auth
    implementation("io.jsonwebtoken:jjwt-api:0.12.6")
    runtimeOnly("io.jsonwebtoken:jjwt-impl:0.12.6")
    runtimeOnly("io.jsonwebtoken:jjwt-jackson:0.12.6")

    // LangChain4j for AI Orchestration
    implementation("dev.langchain4j:langchain4j:0.36.2")
    implementation("dev.langchain4j:langchain4j-google-ai-gemini:0.36.2")
    implementation("dev.langchain4j:langchain4j-pgvector:0.36.2")
    implementation("dev.langchain4j:langchain4j-embeddings-all-minilm-l6-v2:0.36.2")
    implementation("dev.langchain4j:langchain4j-web-search-engine-google-custom:0.36.2")

    // .env file loader
    implementation("me.paulschwarz:spring-dotenv:4.0.0")

    // Phase 1 Performance
    implementation("org.springframework.boot:spring-boot-starter-cache")

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

tasks.named<org.springframework.boot.gradle.tasks.run.BootRun>("bootRun") {
    jvmArgs("-Xmx2g", "-XX:MaxMetaspaceSize=512m")
}

