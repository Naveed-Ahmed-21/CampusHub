# AGENT.md

# CampusHub AI Development Guide

Version: 1.0

---

# Project Overview

CampusHub is a multi-tenant university super app that connects students, faculty, clubs, classrooms, placements, innovation, projects, learning resources, communication, and career development into one platform.

The system is designed to scale from a single college to thousands of colleges while maintaining strict tenant isolation.

The goal is to build production-quality software, not prototype code.

---

# Tech Stack

## Mobile

- Flutter (Latest Stable)
- Riverpod
- GoRouter
- Dio
- Freezed
- Json Serializable

## Backend

- Node.js 22 LTS
- Express.js
- Prisma ORM
- PostgreSQL
- Redis
- Socket.IO
- BullMQ
- Elasticsearch

## Storage

- AWS S3 or Cloudflare R2

## Authentication

- JWT Access Token
- Refresh Token Rotation
- Argon2id Password Hashing

---

# Architecture

Follow Domain Driven Design.

Modules:

- Identity
- Academic
- Community
- Placement
- Innovation
- Communication
- Platform
- Analytics

Every module must be independent.

Never mix business logic between modules.

---

# Repository Pattern

Always use

Controller

↓

Service

↓

Repository

↓

Prisma

↓

PostgreSQL

Controllers must never access Prisma directly.

Repositories contain only database queries.

Business logic belongs inside Services.

---

# Multi-Tenant Rules

Every business entity belongs to one college.

Every table contains

college_id

Every request must automatically filter by

currentUser.college_id

Cross-college data access is prohibited unless explicitly implemented.

---

# Database Rules

Use UUID for every primary key.

Every business table includes

- id
- college_id
- created_at
- updated_at
- deleted_at
- created_by
- updated_by

Use soft deletes.

Never hard delete business data.

---

# Authentication Rules

Access Token

15 minutes

Refresh Token

30 days

Rotate refresh tokens on every refresh.

Store only hashed refresh tokens.

Passwords must use Argon2id.

---

# Authorization

Use RBAC.

Support multiple roles per user.

Example roles

- Student
- Faculty
- Department Admin
- College Admin
- Placement Officer
- Club Coordinator
- Super Admin

Never hardcode permissions.

Permissions use strings such as

assignment.create

assignment.grade

project.manage

placement.publish

---

# Backend Folder Structure

src/

modules/

shared/

config/

infrastructure/

prisma/

Every feature follows:

controllers/

services/

repositories/

routes/

dto/

validators/

events/

tests/

---

# Flutter Folder Structure

lib/

core/

shared/

features/

services/

config/

app/

Every feature owns

presentation/

application/

domain/

data/

widgets/

---

# API Rules

REST APIs only.

Standard success response

{
  "success": true,
  "message": "...",
  "data": {}
}

Standard error response

{
  "success": false,
  "code": "...",
  "message": "...",
  "errors": []
}

Use proper HTTP status codes.

---

# Validation

Validate every request.

Validate

- UUID
- Email
- Pagination
- Enums
- File Upload
- Body
- Query
- Params

Never trust frontend input.

---

# Error Handling

Create custom error classes.

Never expose internal errors.

Log all unexpected exceptions.

Always return consistent responses.

---

# Logging

Use Pino.

Every request includes

trace_id

Log

- Request
- Response
- Errors
- Performance

---

# Storage

Never store direct URLs.

Store

file_id

Use Storage Service.

Supported uploads

- Images
- PDFs
- DOCX
- PPT
- ZIP

---

# Queue

Use BullMQ.

Background jobs

- Emails
- Notifications
- Search indexing
- Image processing
- Scheduled reminders

Never block API responses with long-running jobs.

---

# Search

Use Elasticsearch.

Index

- Resources
- Projects
- Clubs
- Events
- Companies
- Users

---

# Notifications

Single notification service.

Support

- In-app
- Push
- Email (future)

Every notification has

type

title

body

deep_link

read_status

---

# Socket.IO

Use Socket.IO only for

- Chat
- Typing
- Presence
- Notifications

Do not use sockets for standard CRUD.

---

# Testing

Every module must include

Unit Tests

Integration Tests

Repository Tests

API Tests

Do not mark a module complete without tests.

---

# Documentation

Every endpoint requires

- Swagger documentation
- Request examples
- Response examples
- Error responses

---

# Coding Standards

Use

TypeScript strict mode

ESLint

Prettier

SOLID principles

Composition over inheritance

Small reusable functions

Meaningful names

Avoid duplicate code.

---

# Performance

Add indexes for

- Foreign keys
- Email
- Username
- Roll Number
- Created At
- Frequently queried fields

Use Redis only for

- Sessions
- OTP
- Rate limiting
- Dashboard cache
- Search suggestions

---

# Security

Always implement

- Helmet
- CORS
- Rate limiting
- Input validation
- SQL injection prevention
- XSS prevention
- Secure headers

---

# Development Order

1. Setup
2. Database
3. Authentication
4. RBAC
5. Dashboard
6. Academic
7. Community
8. Placement
9. Innovation
10. Chat
11. Search
12. Notifications
13. Admin
14. Testing
15. Deployment

Never skip phases.

---

# AI Coding Rules

When generating code:

- Build one module at a time.
- Finish the backend before frontend integration for that module.
- Generate Prisma models before repositories.
- Generate repositories before services.
- Generate services before controllers.
- Generate controllers before routes.
- Generate DTOs and validators before endpoints.
- Write tests before marking a feature complete.
- Avoid placeholder implementations.
- Prefer reusable code over duplication.
- Keep modules loosely coupled.
- Ask for clarification only when business requirements are genuinely ambiguous.

---

# Project Goal

CampusHub should be maintainable, scalable, secure, modular, and production-ready.

Every implementation decision should prioritize long-term maintainability over short-term convenience.
