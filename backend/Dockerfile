# Stage 1: Build
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /app
COPY gradlew gradlew.bat settings.gradle.kts build.gradle.kts gradle.properties ./
COPY gradle/ gradle/
RUN chmod +x gradlew && ./gradlew dependencies --no-daemon || true
COPY src/ src/
RUN ./gradlew bootJar --no-daemon -x test

# Stage 2: Run (debian-slim, not alpine — ONNX runtime needs glibc + libstdc++)
FROM eclipse-temurin:21-jre
WORKDIR /app
COPY --from=builder /app/build/libs/*.jar app.jar
EXPOSE 8080
# ponytail: 512m heap fits t2.micro alongside postgres; bump to 768m if DB moves off-box
ENTRYPOINT ["java", "-Xmx512m", "-XX:MaxMetaspaceSize=256m", "-jar", "app.jar"]
