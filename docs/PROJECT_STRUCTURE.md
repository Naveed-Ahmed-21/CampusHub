# 📁 CampusHub Project Structure

**Project:** CampusHub
**Version:** 1.0

---

# Overview

CampusHub follows a **monorepo** architecture.

All applications, backend services, database files, documentation, and DevOps configurations are maintained in a single repository.

Benefits:

* Easier dependency management
* Shared documentation
* Shared Git history
* Simplified CI/CD
* Consistent versioning

---

# Repository Structure

```text
CampusHub/
│
├── apps/
│   └── campus_hub_app/      # Unified Flutter multi-platform application
│
├── backend/
│   ├── prisma/              # Prisma schema & migrations
│   └── src/                 # Modular Express + Socket.IO API
│
├── docs/                    # Architecture & specifications
│
├── assets/                  # Shared graphic assets
│
├── docker-compose.yml       # Multi-container orchestration
│
├── .github/                 # CI/CD Workflows
│
├── README.md
├── LICENSE
├── CHANGELOG.md
├── CONTRIBUTING.md
├── SECURITY.md
└── PROJECT_STRUCTURE.md
```

---

# Applications

## campus_hub_app

Unified Flutter application for:

* Students
* Faculty
* Placement Officers
* Administrators

Technology:

* Flutter
* Riverpod
* GoRouter
* Dio
* Socket.IO Client
* Flutter Secure Storage
* Freezed & Json Serializable

---

# Backend

```text
backend/
├── prisma/
│   ├── schema.prisma
│   └── seed.ts
└── src/
    ├── config/
    ├── infrastructure/
    ├── modules/
    ├── shared/
    ├── app.ts
    └── server.ts
```

---

## api

Main REST API.

Structure

```text
src/

config/

middleware/

modules/

prisma/

utils/

server.ts
```

---

## socket

Dedicated Socket.IO server (optional in Version 1).

Responsibilities

* Real-time messaging
* Presence
* Typing indicators

---

# Backend Modules

Every feature follows the same structure.

Example

```text
modules/

auth/

controller.ts

service.ts

repository.ts

route.ts

validation.ts

types.ts
```

Modules

```text
auth

users

departments

feed

clubs

chat

career

events

placement

portfolio

notifications
```

Each module owns its business logic.

---

# Flutter Structure

```text
lib/

app/

config/

core/

shared/

features/

providers/

repositories/

services/

theme/

widgets/

main.dart
```

---

# Feature Structure

Each feature uses the same layout.

```text
features/

auth/

presentation/

domain/

data/

providers/

repository/

widgets/
```

Examples

```text
feed/

chat/

clubs/

career/

profile/

events/

settings/
```

---

# Database

```text
backend/prisma/
├── schema.prisma
├── seed.ts
└── migrations/
```

Contains:

* Prisma schema & relations
* Database migrations
* Seed scripts

---

# Documentation

```text
docs/
├── Project_Vision.md
├── PRD.md
├── User_Flows.md
├── API_Specification.md
├── System_Architecture.md
├── UI_Design_Guidelines.md
├── Development_Roadmap.md
├── Contribution_Guide.md
├── Coding_Standards.md
├── SECURITY.md
├── DEPLOYMENT.md
├── TESTING.md
├── CHANGELOG.md
├── TECH_STACK.md
├── FAQ.md
├── LICENSE.md
├── OPEN_SOURCE_GUIDE.md
├── RELEASE_PROCESS.md
├── PROJECT_STRUCTURE.md
└── database/
    ├── Database_ERD.md
    └── database_schema.dbml
```

Documentation is version-controlled and updated alongside code.

---

# Assets

```text
assets/

logos/

icons/

illustrations/

images/

branding/
```

Used across Flutter and documentation.

---

# Docker

```text
docker/

Dockerfile.api

Dockerfile.mobile

docker-compose.yml
```

Supports local development and production deployments.

---

# Scripts

Utility scripts.

Examples

```text
scripts/

setup.sh

seed.sh

backup.sh

deploy.sh
```

---

# GitHub Configuration

```text
.github/

workflows/

ISSUE_TEMPLATE/

PULL_REQUEST_TEMPLATE.md

CODE_OF_CONDUCT.md

CONTRIBUTING.md

SECURITY.md
```

---

# Environment Variables

Backend

```text
.env
.env.example
```

Flutter

```text
--dart-define
```

Never commit secrets.

---

# Naming Conventions

Folders

```text
snake_case
```

Examples

```text
career_hub

user_profile

club_feed
```

Files

Flutter

```text
login_screen.dart

post_card.dart

career_repository.dart
```

Backend

```text
auth.controller.ts

feed.service.ts

club.repository.ts
```

---

# Module Independence

Every module should contain:

* Models
* Services
* Validation
* Routes
* Business logic

Avoid tight coupling between modules.

---

# Shared Code

Flutter

```text
shared/

widgets/

extensions/

constants/

helpers/
```

Backend

```text
utils/

middleware/

config/
```

Only reusable code belongs here.

---

# Build Output

Flutter

```text
build/
```

Backend

```text
dist/
```

These directories should not contain manually edited files.

---

# Configuration Files

Repository root

```text
pubspec.yaml

package.json

docker-compose.yml

README.md

LICENSE

.gitignore

.editorconfig

.prettierrc

analysis_options.yaml

eslint.config.js
```

These files define tooling and project standards.

---

# Repository Growth

Version 1

```text
~20 folders
~15 database tables
~50 API endpoints
```

Version 2

```text
Innovation Hub

Assignments

Attendance

Marketplace
```

Version 3

```text
AI

Multi-college

Alumni

Mentorship
```

The structure is designed to expand without major reorganization.

---

# Design Principles

* Feature-first
* Modular
* Reusable
* Scalable
* Testable
* Documented
* Consistent

---

# Conclusion

CampusHub's repository structure is designed to support long-term development by multiple contributors. A predictable folder hierarchy, modular architecture, and shared conventions make the project easier to understand, maintain, and scale as new features and contributors are added.
