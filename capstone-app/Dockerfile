
# --- Stage 1: Build Environment ---
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /build
# Cache dependencies by copying only the pom.xml first
COPY pom.xml .
RUN mvn dependency:go-offline -B
# Copy source and compile the production JAR file
COPY src ./src
RUN mvn clean package -DskipTests
# --- Stage 2: Minimal Secure Runtime Environment ---
# Google Distroless JRE images contain zero OS binaries, shells, or package managers
FROM gcr.io/distroless/java17-debian12:latest
WORKDIR /app
# Copy the compiled artifact safely from the builder layer
COPY --from=builder /build/target/springboot-app-1.0.0.jar app.jar
# Enforce secure running conditions by defaulting to a non-root system user (built into
distroless)
USER nonroot:nonroot
EXPOSE 8080
# Execute the application binary securely
ENTRYPOINT ["java", "-jar", "app.jar"]