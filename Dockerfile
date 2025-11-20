# Dockerfile – Optimized for Java/Spring Boot Microservices
FROM amazoncorretto:21-alpine3.20 AS builder

WORKDIR /app
COPY . .

# Build with Gradle or Maven (detect automatically)
RUN if [ -f "gradlew" ]; then \
        ./gradlew clean bootJar -x test; \
    elif [ -f "mvnw" ]; then \
        ./mvnw clean package -DskipTests; \
    else \
        echo "No Gradle or Maven wrapper found!" && exit 1; \
    fi

# Final stage – Ultra lightweight runtime
FROM amazoncorretto:21-alpine3.20

# Create non-root user
RUN addgroup -g 1001 -S appgroup && \
    adduser -S appuser -u 1001 -G appgroup

WORKDIR /app

# Copy only the built JAR from builder stage
COPY --from=builder /app/build/libs/*.jar app.jar
# For Maven projects use: COPY --from=builder /app/target/*.jar app.jar

# Run as non-root user
USER appuser

# Expose port (change per service if needed)
EXPOSE 8080

# Health check
HEALTHCHECK --interval=30s --timeout=3s --start-period=20s --retries=3 \
    CMD wget --no-verbose --tries=1 --spider http://localhost:8080/actuator/health || exit 1

# JVM tuning for containers
ENV JAVA_OPTS="-Xms256m -Xmx512m -XX:+UseG1GC"

ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -jar app.jar"]
