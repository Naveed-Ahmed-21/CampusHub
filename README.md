# 🚀 CampusHub

<div align="center">

# One Campus. One Platform.

*A modern, production-ready open-source digital campus ecosystem built with Flutter, Node.js, Express, TypeScript, Prisma ORM, and PostgreSQL.*

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev)
[![Node.js](https://img.shields.io/badge/Node.js-22.x-339933?logo=nodedotjs)](https://nodejs.org)
[![TypeScript](https://img.shields.io/badge/TypeScript-5.x-3178C6?logo=typescript)](https://www.typescriptlang.org)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-17-4169E1?logo=postgresql)](https://www.postgresql.org)
[![Prisma](https://img.shields.io/badge/Prisma-5.x-2D3748?logo=prisma)](https://www.prisma.io)
[![Docker](https://img.shields.io/badge/Docker-Enabled-2496ED?logo=docker)](https://www.docker.com)

</div>

---

## 📖 About CampusHub

**CampusHub** is a unified, multi-tenant digital campus ecosystem designed to connect students, faculty, placement officers, department heads, and campus administrators.

Instead of relying on fragmented tools (WhatsApp groups, spreadsheets, email threads, isolated LMS systems), CampusHub integrates academics, communications, clubs, career development, placements, event management, real-time messaging, and student portfolios into a cohesive, secure experience.

---

## 🏗️ Architecture & Core Principles

CampusHub is structured as a **Monorepo** enforcing strict separation of concerns, scalability, and maintainability:

- **Monorepo Workspace**: NPM Workspaces organizing the Node.js TypeScript API backend (`/backend`) and Flutter cross-platform mobile application (`/apps/campus_hub_app`).
- **Feature-First Architecture (Mobile)**: Each domain (Auth, Feed, Clubs, Chat, Events, Placements, Profile) is self-contained with Clean Architecture layers (`data`, `domain`, `presentation`).
- **Modular Architecture (Backend)**: Encapsulated domain modules (`identity`, `users`, `feed`, `clubs`, `events`, `chat`, `placements`) containing explicit DTOs, controllers, services, repositories, and routes.
- **State Management & Routing**: Flutter Riverpod (`flutter_riverpod`) for reactive state dependency injection, `GoRouter` for declarative navigation and auth redirection guards.
- **Networking**: `Dio` with request/response interceptors for automatic JWT bearer token header injection and token refresh retries.
- **Real-Time Communication**: `Socket.IO` server/client architecture supporting real-time room channels (`user`, `department`, `club`, `event`).
- **Database & ORM**: PostgreSQL 17 managed via Prisma ORM with explicit migrations and type-safe client generation.
- **Containerization & CI/CD**: Docker Compose orchestration for local development and GitHub Actions pipelines for automated static analysis, linting, build checks, and testing.

---

## 🛠️ Technology Stack

| Layer | Technology | Description |
| :--- | :--- | :--- |
| **Mobile App** | [Flutter](https://flutter.dev) | Cross-platform mobile framework (iOS & Android) |
| **State Management** | [Riverpod](https://riverpod.dev) | Compile-safe state management & dependency injection |
| **Mobile Router** | [GoRouter](https://pub.dev/packages/go_router) | Declarative URL-based routing & auth guards |
| **Mobile HTTP** | [Dio](https://pub.dev/packages/dio) | Feature-rich HTTP client with interceptors |
| **Backend Framework**| [Node.js](https://nodejs.org) + [Express.js](https://expressjs.com) | Fast, modular, event-driven REST & WebSocket API |
| **Language** | [TypeScript](https://www.typescriptlang.org) | Strict static typing across backend services |
| **Database** | [PostgreSQL 17](https://www.postgresql.org) | Multi-tenant relational database engine |
| **ORM** | [Prisma](https://www.prisma.io) | Next-generation Node.js & TypeScript ORM |
| **Realtime Engine** | [Socket.IO](https://socket.io) | Low-latency bi-directional WebSocket communication |
| **Authentication** | [JWT](https://jwt.io) + Argon2 | Access & refresh token auth with role-based access control (RBAC) |
| **Containerization** | [Docker](https://www.docker.com) & Docker Compose | Multi-container development & production environment |
| **CI/CD** | [GitHub Actions](https://github.com/features/actions) | Automated linting, type-checking, building & testing |

---

## 📁 Repository Directory Structure

```text
CampusHub/
├── .github/
│   └── workflows/
│       ├── ci-backend.yml              # GitHub Actions CI for Node.js Backend
│       └── ci-flutter.yml              # GitHub Actions CI for Flutter Mobile App
├── apps/
│   └── campus_hub_app/                 # Flutter Mobile Application
│       ├── lib/
│       │   ├── main.dart               # App entrypoint (ProviderScope + MaterialApp.router)
│       │   ├── core/                   # Core shared utilities & configuration
│       │   │   ├── config/             # Environment settings (AppConfig)
│       │   │   ├── constants/          # API endpoint routes
│       │   │   ├── errors/             # Failure & Exception domain hierarchies
│       │   │   ├── network/            # Dio ApiClient, AuthInterceptor, SocketService
│       │   │   ├── router/             # GoRouter setup with route declarations
│       │   │   ├── storage/            # SecureStorageService wrapper
│       │   │   └── theme/              # Material 3 light/dark themes
│       │   └── features/               # Feature-first domain modules
│       │       ├── auth/               # Authentication (data, domain, presentation)
│       │       ├── feed/               # Department & Campus Feed
│       │       ├── clubs/              # Student Clubs & Communities
│       │       ├── chat/               # Real-time Chat
│       │       ├── events/             # Campus Events Calendar
│       │       ├── placements/         # Placement Hub & Job Drives
│       │       └── profile/            # User Profile & Portfolio
│       ├── pubspec.yaml                # Flutter package dependencies
│       └── analysis_options.yaml       # Dart linter configuration
├── backend/                            # Node.js + Express + TypeScript API Server
│   ├── Dockerfile                      # Multi-stage Docker container specification
│   ├── package.json                    # Backend dependencies & npm scripts
│   ├── tsconfig.json                   # TypeScript strict compiler configuration
│   ├── prisma/
│   │   ├── schema.prisma               # Prisma ORM Database Schema
│   │   └── seed.ts                     # Database initial seeding script
│   └── src/
│       ├── server.ts                   # HTTP & Socket.IO server bootstraper
│       ├── app.ts                      # Express app setup & route mounting
│       ├── config/                     # Environment schema validation (Zod)
│       ├── infrastructure/             # Prisma client, Pino logger, Socket server
│       ├── shared/                     # Middlewares (auth, error, validation) & utils
│       └── modules/                    # Modular domain endpoints
│           ├── identity/               # Auth controllers, services, repos, routes, DTOs
│           ├── users/                  # User profile management
│           ├── feed/                   # Feed post management
│           ├── clubs/                  # Student club management
│           ├── events/                 # Event scheduling & management
│           ├── chat/                   # Real-time messaging
│           └── placements/             # Placement drives & applications
├── docker-compose.yml                  # Docker Compose configuration (Postgres + Redis + API)
├── .env.example                        # Environment variables template
├── .dockerignore                       # Docker build context exclusion rules
├── package.json                        # Monorepo root workspace configuration
└── README.md                           # Master setup & developer documentation
```

---

## ⚡ Quickstart & Setup Guide

### 1. Prerequisites
Ensure your local development machine has the following installed:
- **Node.js**: `v22.x` or higher (`node --version`)
- **NPM**: `v10.x` or higher (`npm --version`)
- **Flutter SDK**: `v3.16.0` or higher (`flutter --version`)
- **Docker & Docker Compose**: Installed and running (`docker compose version`)
- **Git**: Installed (`git --version`)

---

### 2. Clone Repository & Setup Environment
```bash
# Clone the repository
git clone https://github.com/<your-org>/CampusHub.git
cd CampusHub

# Create environment configuration from template
cp .env.example .env
cp .env.example backend/.env
```

---

### 3. Start Database Services via Docker
```bash
# Spin up PostgreSQL (v17) and Redis containers
npm run docker:up

# Check container status
docker compose ps
```

---

### 4. Setup Backend & Run Database Migrations
```bash
# Install all monorepo dependencies
npm install

# Generate Prisma Client types
npm run prisma:generate

# Run Prisma migrations to construct database tables
npm run prisma:migrate

# Seed database with initial sample data (Admin, Faculty, Student, Clubs, Drives)
npm run prisma:seed

# Start Node.js API server in live-reload development mode
npm run backend:dev
```
> The API server will start at `http://localhost:5000/api/v1` and WebSocket at `ws://localhost:5000/socket.io/`.  
> Test health check endpoint: `curl http://localhost:5000/health`.

---

### 5. Launch Flutter Mobile Application
```bash
# Navigate to mobile app workspace
cd apps/campus_hub_app

# Fetch Flutter dependencies
flutter pub get

# Run static analysis
flutter analyze

# Launch Flutter app in target emulator or device
flutter run
```

---

## 🔑 Environment Variables Reference

| Variable | Description | Default / Example |
| :--- | :--- | :--- |
| `NODE_ENV` | Runtime environment mode | `development` / `production` |
| `PORT` | Backend HTTP API Port | `5000` |
| `DATABASE_URL` | PostgreSQL connection string | `postgresql://postgres:postgres@localhost:5432/campushub?schema=public` |
| `REDIS_URL` | Redis connection URL | `redis://localhost:6379` |
| `JWT_ACCESS_SECRET` | Secret key for access token signing | `super_secret_access_key_min_32_chars` |
| `JWT_REFRESH_SECRET` | Secret key for refresh token signing | `super_secret_refresh_key_min_32_chars` |
| `JWT_ACCESS_EXPIRES_IN` | Access token lifespan | `15m` |
| `JWT_REFRESH_EXPIRES_IN` | Refresh token lifespan | `7d` |
| `CORS_ORIGIN` | Allowed cross-origin domains | `*` |
| `FLUTTER_APP_API_BASE_URL` | Base REST API URL for Flutter app | `http://10.0.2.2:5000/api/v1` (Android Emulator) |
| `FLUTTER_APP_SOCKET_URL` | Socket.IO server URL for Flutter app | `http://10.0.2.2:5000` |

---

## 🛠️ Monorepo NPM Commands Cheat Sheet

| Command | Action |
| :--- | :--- |
| `npm run backend:dev` | Launch Node.js backend in development mode with live reload (`tsx`) |
| `npm run backend:build` | Compile TypeScript source code and generate Prisma client |
| `npm run backend:start` | Run compiled production build from `dist/server.js` |
| `npm run backend:lint` | Execute ESLint across backend TypeScript codebase |
| `npm run prisma:generate` | Generate Prisma Client code based on `schema.prisma` |
| `npm run prisma:migrate` | Execute pending database schema migrations |
| `npm run prisma:studio` | Open interactive Prisma Studio web interface |
| `npm run prisma:seed` | Execute seed script (`seed.ts`) to populate default data |
| `npm run docker:up` | Boot up PostgreSQL, Redis, and Backend via Docker Compose |
| `npm run docker:down` | Stop and tear down Docker containers |
| `npm run flutter:get` | Execute `flutter pub get` inside Flutter mobile app |
| `npm run flutter:analyze` | Execute `flutter analyze` static analysis check |
| `npm run flutter:test` | Execute Flutter unit and widget test suites |

---

## 🛡️ Best Practices & Architectural Guidelines

1. **Clean Code & Layering**:
   - Flutter features must never violate layer direction: `Presentation -> Domain <- Data`.
   - Domain layers contain abstract repository interfaces and entities without external SDK dependencies.
   - Backend modules strictly enforce: `Route -> Middleware/Validation -> Controller -> Service -> Repository -> Database`.

2. **Error & Exception Handling**:
   - HTTP response formats are standardized using `ResponseUtil.success` and `ResponseUtil.error`.
   - Custom app failures subclass `Failure` (Flutter) or `AppError` (Backend) with explicit HTTP status codes.

3. **Security & Authentication**:
   - Never commit `.env` or API credentials to version control.
   - User passwords must be hashed using `argon2`.
   - Bearer access tokens must be stored in secure encrypted storage (`FlutterSecureStorage`).
   - Role-Based Access Control (RBAC) guards must be applied to restricted API routes using `requireRoles(...)`.

4. **Git & Code Quality**:
   - Run `flutter analyze` and `npm run backend:lint` before opening pull requests.
   - Both Flutter and Backend CI workflows automatically block pull requests with failing builds, type errors, or unformatted code.

---

## 🤝 Contributing

We welcome contributions from open-source developers, students, faculty, and engineers!

1. Fork the Repository.
2. Create a Feature Branch (`git checkout -b feature/amazing-feature`).
3. Commit your changes (`git commit -m 'feat: Add amazing feature'`).
4. Push to the Branch (`git push origin feature/amazing-feature`).
5. Open a Pull Request.

---

## 🪪 License

Distributed under the **MIT License**. See `LICENSE` for more information.

<div align="center">

Made with ❤️ by **Naveed Ahmed K**.

</div>
