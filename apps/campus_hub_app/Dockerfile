# Multi-stage Dockerfile for CampusHub Flutter Web Frontend

# Stage 1: Build Flutter Web Bundle
FROM ghcr.io/cirrusci/flutter:3.27.0 AS builder

WORKDIR /app

# Copy dependency configs
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy source code and build web bundle
COPY . .
RUN flutter build web --release --web-renderer canvaskit

# Stage 2: Serve Web Application via Nginx
FROM nginx:1.27-alpine AS runner

# Copy Nginx static site config
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled Flutter web build from builder stage
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
