# 🏗️ CampusHub System Architecture

**Version:** 1.0

**Project:** CampusHub

**Architecture Style:** Modular Monolith

**Backend:** Node.js + Express + Prisma

**Frontend:** Flutter

**Database:** PostgreSQL

---

# Table of Contents

1. Overview
2. Architecture Principles
3. High-Level Architecture
4. Client Layer
5. Backend Layer
6. Database Layer
7. External Services
8. Module Architecture
9. Authentication Flow
10. Feed Architecture
11. Chat Architecture
12. Career Hub Architecture
13. Notifications
14. Deployment
15. Scalability
16. Future Evolution

---

# 1. Overview

CampusHub is designed using a modular architecture.

Every major feature is developed as an independent module.

Examples:

- Authentication
- Feed
- Clubs
- Chat
- Career Hub
- Placement
- Portfolio
- Notifications

Each module owns its business logic while sharing the same database.

---

# 2. Architecture Principles

The system follows these principles:

- Modular
- Scalable
- Maintainable
- Secure
- Mobile-first
- API-first
- Cloud-ready

---

# 3. High-Level Architecture

```text
                 Flutter Mobile App
                         │
                         │ HTTPS / REST
                         ▼
                 Express REST API
                         │
      ┌──────────────────┼──────────────────┐
      │                  │                  │
 Authentication      Business Logic      Socket.IO
      │                  │                  │
      └──────────────────┼──────────────────┘
                         │
                    Prisma ORM
                         │
                   PostgreSQL
                         │
        ┌────────────────┴────────────────┐
        │                                 │
    ImageKit                         Firebase
 (Images / Files)              Push Notifications
```

---

# 4. Frontend Architecture

Flutter follows Feature-First Architecture.

```text
lib/

app/

core/

shared/

features/

services/

providers/

repositories/

models/

widgets/
```

Each feature contains

```text
presentation/

domain/

data/

providers/

repository/

widgets/
```

---

# 5. Backend Architecture

Backend follows Modular Architecture.

```text
src/

config/

middleware/

modules/

socket/

prisma/

utils/

server.ts
```

Every module contains

```text
controller.ts

service.ts

repository.ts

route.ts

validation.ts

types.ts
```

Responsibilities

Controller

↓

HTTP Requests

↓

Service

↓

Business Logic

↓

Repository

↓

Database

---

# 6. Database Layer

Database

↓

PostgreSQL

↓

Prisma ORM

All business logic interacts with the database through repositories.

No controller accesses Prisma directly.

---

# 7. External Services

## Firebase

Used for

- Push Notifications

---

## ImageKit

Used for

- Profile Images
- Post Images
- Club Logos
- Chat Documents & Media
- Resumes & Certificates

---

## AWS S3 (Future)

Used for

- Documents
- Videos
- Large Files

---

# 8. Module Architecture

Authentication

↓

Users

↓

Departments

↓

Feed

↓

Clubs

↓

Chat

↓

Career

↓

Events

↓

Placement

↓

Portfolio

↓

Notifications

Modules communicate through services, not by directly accessing each other's database logic.

---

# 9. Authentication Flow

```text
Flutter

↓

POST /auth/login

↓

JWT Access Token

↓

Refresh Token

↓

Secure Storage

↓

Authenticated Requests
```

Every protected request includes

```
Authorization: Bearer <token>
```

---

# 10. Feed Architecture

```text
Create Post

↓

Validate

↓

Store in Database

↓

Upload Media (ImageKit)

↓

Create Feed Entry

↓

Notify Followers
```

Feed Types

- My Feed
- Related Feed
- Cross Feed
- Club Feed
- Following Feed

---

# 11. Chat Architecture

```text
Flutter

↓

Socket.IO

↓

Express Socket Server

↓

Persist Message

↓

Broadcast

↓

Recipient
```

Messages are stored before delivery.

If a recipient is offline, messages remain available when they reconnect.

---

# 12. Career Hub Architecture

```text
Roadmaps

↓

Topics

↓

Resources

↓

Student Progress

↓

Dashboard
```

Each roadmap is composed of ordered topics.

Each topic contains multiple learning resources.

Student progress is stored separately.

---

# 13. Notification Architecture

Triggers

- New Message
- New Event
- Club Activity
- Placement Drive
- Career Reminder

Flow

```text
Event Occurs

↓

Notification Service

↓

Database

↓

Firebase Cloud Messaging

↓

Flutter App
```

---

# 14. Security Architecture

Authentication

- JWT
- Refresh Tokens

Authorization

- Role-Based Access Control (RBAC)

Passwords

- Argon2id hashing

Transport

- HTTPS

Validation

- Zod

Rate Limiting

- Express Rate Limit

Security Headers

- Helmet

---

# 15. Error Handling

Global Error Handler

↓

Controller

↓

Service

↓

Repository

↓

Database

Every API returns

```json
{
  "success": false,
  "message": "...",
  "errors": []
}
```

---

# 16. Logging

Development

- Console Logs

Production

- Winston / Pino

Future

- Grafana
- Loki

---

# 17. Caching (Future)

Redis

Used for

- Feed
- Sessions
- Search
- Frequently Accessed Data

---

# 18. Search

Version 1

PostgreSQL Full Text Search

Version 2

Elasticsearch

---

# 19. Deployment Architecture

```text
Flutter App
      │
      ▼
Internet
      │
      ▼
Nginx Reverse Proxy
      │
      ▼
Express API
      │
      ▼
Prisma ORM
      │
      ▼
PostgreSQL
```

Media

↓

ImageKit

Notifications

↓

Firebase

---

# 20. Scalability Plan

Version 1

Single Backend

↓

Version 2

Modular Monolith

↓

Version 3

Microservices

Possible services

- Chat
- AI
- Notifications
- Search

---

# 21. Monitoring

Future

- Grafana
- Prometheus
- Sentry
- Uptime Robot

---

# 22. CI/CD Pipeline

```text
Developer

↓

Feature Branch

↓

Pull Request

↓

Code Review

↓

GitHub Actions

↓

Automated Tests

↓

Build

↓

Deploy
```

---

# 23. Folder Structure

Repository

```text
CampusHub/

apps/

backend/

database/

docs/

.github/

docker/
```

Flutter

```text
features/

core/

shared/

services/

providers/
```

Backend

```text
modules/

middleware/

config/

prisma/

socket/
```

---

# 24. Future Multi-College Support

Architecture already supports

Campus

↓

Departments

↓

Users

↓

Resources

↓

Events

Each college is isolated through the `campus` entity while sharing the same platform.

---

# 25. Design Decisions

✔ Feature-first Flutter architecture

✔ Modular Node.js backend

✔ PostgreSQL relational database

✔ Prisma ORM

✔ JWT Authentication

✔ Socket.IO for real-time communication

✔ Firebase Cloud Messaging

✔ ImageKit media storage

✔ REST API

✔ Modular scalability

---

# Conclusion

CampusHub is built as a modular, API-first platform that separates presentation, business logic, and data access into well-defined layers.

The chosen architecture keeps Version 1 simple enough for a student team to build while leaving clear paths for future growth, including AI features, multi-college support, advanced search, analytics, and eventually a microservices architecture if the platform expands.
