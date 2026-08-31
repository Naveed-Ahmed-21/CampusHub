# 🚀 CampusHub Deployment Guide

**Project:** CampusHub

**Version:** 1.0

**Last Updated:** August 2026

---

# Table of Contents

1. Overview
2. Requirements
3. Local Development
4. Backend Deployment
5. Database Setup
6. Flutter Build
7. Docker Deployment
8. Reverse Proxy
9. SSL Configuration
10. Environment Variables
11. CI/CD
12. Monitoring
13. Backup Strategy
14. Rollback Strategy
15. Troubleshooting

---

# 1. Overview

CampusHub supports three environments.

| Environment | Purpose |
|------------|----------|
| Development | Local development |
| Staging | Testing before release |
| Production | Live application |

---

# 2. Technology Stack

Frontend

- Flutter

Backend

- Node.js
- Express

Database

- PostgreSQL

ORM

- Prisma

Storage

- ImageKit

Notifications

- Firebase Cloud Messaging

Deployment

- Docker
- Nginx
- Ubuntu Server

---

# 3. Local Development

Clone Repository

```bash
git clone https://github.com/<your-org>/CampusHub.git
```

Move into project

```bash
cd CampusHub
```

---

## Backend

```bash
cd backend
npm install
```

Create

```
.env
```

Example

```env
DATABASE_URL=
JWT_ACCESS_SECRET=
JWT_REFRESH_SECRET=

PORT=5000

IMAGEKIT_PUBLIC_KEY=
IMAGEKIT_PRIVATE_KEY=
IMAGEKIT_URL_ENDPOINT=

FIREBASE_SERVER_KEY=
```

Run migrations

```bash
npx prisma migrate dev
```

Generate Prisma Client

```bash
npx prisma generate
```

Seed database (optional)

```bash
npm run seed
```

Run backend

```bash
npm run dev
```

Backend URL

```
http://localhost:5000
```

---

## Flutter

Move to app

```bash
cd apps/campus_hub_app
```

Install packages

```bash
flutter pub get
```

Run

```bash
flutter run
```

---

# 4. PostgreSQL Setup

Install PostgreSQL

Ubuntu

```bash
sudo apt install postgresql
```

Create database

```sql
CREATE DATABASE campushub;
```

Create user

```sql
CREATE USER campushub_user WITH PASSWORD 'your_password';
```

Grant permissions

```sql
GRANT ALL PRIVILEGES ON DATABASE campushub TO campushub_user;
```

---

# 5. Prisma

Generate client

```bash
npx prisma generate
```

Run migrations

```bash
npx prisma migrate deploy
```

View database

```bash
npx prisma studio
```

---

# 6. Flutter Release

Android APK

```bash
flutter build apk
```

Android App Bundle

```bash
flutter build appbundle
```

Web

```bash
flutter build web
```

---

# 7. Docker

Example Dockerfile (Backend)

```dockerfile
FROM node:22-alpine

WORKDIR /app

COPY package*.json ./

RUN npm install

COPY . .

RUN npm run build

EXPOSE 3000

CMD ["npm","start"]
```

---

Docker Compose

```yaml
version: "3.9"

services:

  api:
    build: .
    ports:
      - "3000:3000"

  postgres:
    image: postgres:17
```

Run

```bash
docker compose up -d
```

---

# 8. Nginx Reverse Proxy

Example

```nginx
server {

    server_name api.campushub.app;

    location / {

        proxy_pass http://localhost:3000;

    }

}
```

Reload

```bash
sudo systemctl reload nginx
```

---

# 9. SSL

Install Certbot

```bash
sudo apt install certbot
```

Generate certificate

```bash
sudo certbot --nginx
```

Verify

```bash
https://api.campushub.app
```

---

# 10. Environment Variables

Backend

```env
DATABASE_URL=

JWT_ACCESS_SECRET=

JWT_REFRESH_SECRET=

PORT=

NODE_ENV=

IMAGEKIT_PUBLIC_KEY=

IMAGEKIT_PRIVATE_KEY=

IMAGEKIT_URL_ENDPOINT=

FIREBASE_SERVER_KEY=
```

Flutter

```env
API_BASE_URL=

SOCKET_URL=
```

Never commit `.env` files.

---

# 11. GitHub Actions CI/CD

Workflow

```text
Push

↓

GitHub Actions

↓

Install Dependencies

↓

Run Tests

↓

Build

↓

Deploy
```

Suggested checks

Flutter

```bash
flutter analyze

flutter test
```

Backend

```bash
npm run lint

npm run test

npm run build
```

---

# 12. Monitoring

Recommended tools

- Uptime Kuma
- Grafana
- Prometheus
- Sentry

Monitor

- CPU
- RAM
- API latency
- Database connections
- Error rates

---

# 13. Logging

Development

Console

Production

Pino

Store logs separately from application files.

---

# 14. Backup Strategy

Database

Daily

Keep backups for 30 days.

Uploads

ImageKit media storage enabled.

Configuration

Version-controlled.

---

# 15. Rollback Strategy

If deployment fails

1. Stop new deployment.
2. Restore previous Docker image.
3. Restore database backup if required.
4. Verify health checks.
5. Re-enable traffic.

---

# 16. Health Check

Recommended endpoint

```
GET /api/v1/health
```

Response

```json
{
  "status": "ok",
  "version": "1.0.0",
  "uptime": 123456
}
```

---

# 17. Production Checklist

Before release

- [ ] Tests passing
- [ ] Build successful
- [ ] Environment variables configured
- [ ] Database migrations completed
- [ ] SSL enabled
- [ ] Backups configured
- [ ] Logging enabled
- [ ] Monitoring enabled
- [ ] Rate limiting enabled
- [ ] Security headers enabled

---

# 18. Deployment Architecture

```text
                Users
                  │
                  ▼
          Flutter Mobile App
                  │
             HTTPS / REST
                  │
                  ▼
          Nginx Reverse Proxy
                  │
                  ▼
          Node.js + Express API
                  │
          ┌───────┴────────┐
          │                │
          ▼                ▼
      PostgreSQL      ImageKit
          │
          ▼
       Prisma ORM

Push Notifications
        │
        ▼
 Firebase Cloud Messaging
```

---

# 19. Recommended Hosting

## Backend

- Railway (Development)
- Render (Development)
- VPS (Production)
- DigitalOcean Droplet
- Hetzner Cloud

---

## Database

- PostgreSQL on VPS
- Neon (Development)
- Supabase PostgreSQL (Development)

---

## Storage

- ImageKit

---

## Mobile

- Google Play Store
- Apple App Store (Future)

---

# 20. Versioning

Use Semantic Versioning

```
1.0.0

1.1.0

1.2.0

2.0.0
```

---

# Conclusion

CampusHub is designed to support a simple local setup for contributors while providing a clear path to production deployment using Docker, Nginx, PostgreSQL, and HTTPS. By following this guide, contributors can deploy the application consistently across development, staging, and production environments.
