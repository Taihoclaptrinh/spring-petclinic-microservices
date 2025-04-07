# Stage 1: Build ứng dụng
FROM maven:3.9.6-eclipse-temurin-17 AS build

WORKDIR /app

# Copy toàn bộ source code vào container
COPY . .

# Nhận tên service từ biến ARG và build ứng dụng
ARG SERVICE_NAME
RUN mvn -pl ${SERVICE_NAME} -am clean package -DskipTests

# Stage 2: Run ứng dụng
FROM openjdk:17-jdk

WORKDIR /application

# Set môi trường
ENV SPRING_PROFILES_ACTIVE=docker
ENV JAVA_HOME=/usr/local/openjdk-17
ENV PATH=$JAVA_HOME/bin:$PATH

# Expose cổng cho ứng dụng
ARG SERVICE_PORT
EXPOSE ${SERVICE_PORT}

# Copy jar file đã build từ stage build vào container
ARG SERVICE_NAME
COPY --from=build /app/${SERVICE_NAME}/target/*.jar app.jar

# Giải nén JAR nếu service_name là genai
ARG SERVICE_NAME
RUN if [ "$SERVICE_NAME" = "spring-petclinic-genai-service" ]; then \
      jar xf app.jar; \
    fi

# Sử dụng biến môi trường để xác định cách khởi động ứng dụng
ARG SERVICE_NAME
ENTRYPOINT ["/bin/sh", "-c", "if [ \"$SERVICE_NAME\" = \"spring-petclinic-genai-service\" ]; then java -cp BOOT-INF/lib/*:BOOT-INF/classes org.springframework.samples.petclinic.genai.GenAIServiceApplication; else java -jar app.jar; fi"]