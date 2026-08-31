# 🤝 CampusHub Contribution Guide

Welcome to **CampusHub**!

Thank you for your interest in contributing to CampusHub.

CampusHub is an open-source digital campus ecosystem that helps students, faculty, and institutions learn, collaborate, innovate, and grow.

Whether you're fixing bugs, improving documentation, designing UI, or building new features, your contribution is valuable.

---

# Table of Contents

1. Code of Conduct
2. Ways to Contribute
3. Getting Started
4. Project Structure
5. Development Setup
6. Branch Strategy
7. Commit Guidelines
8. Pull Request Process
9. Coding Standards
10. Reporting Issues
11. Feature Requests
12. Community Guidelines

---

# Code of Conduct

Please be respectful.

We encourage:

- Friendly discussions
- Constructive feedback
- Professional communication
- Inclusive collaboration

We do not tolerate:

- Harassment
- Hate speech
- Spam
- Personal attacks

---

# Ways to Contribute

You can contribute by:

- Fixing bugs
- Improving UI
- Writing documentation
- Creating new features
- Optimizing performance
- Writing tests
- Reviewing Pull Requests
- Improving accessibility

---

# Project Structure

```
CampusHub/

apps/
backend/
database/
docs/
.github/
```

Flutter code

```
apps/campus_hub_app/
```

Backend

```
backend/
```

Documentation

```
docs/
```

---

# Getting Started

## 1. Fork Repository

Fork CampusHub.

---

## 2. Clone

```
git clone https://github.com/<your-username>/CampusHub.git
```

---

## 3. Install Flutter Packages

```bash
cd apps/campus_hub_app
flutter pub get
```

---

## 4. Install Backend Packages

```bash
cd backend
npm install
```

---

## 5. Configure Environment

Create

```
.env
```

Example

```
DATABASE_URL=

JWT_ACCESS_SECRET=

JWT_REFRESH_SECRET=

IMAGEKIT_PUBLIC_KEY=

IMAGEKIT_PRIVATE_KEY=

IMAGEKIT_URL_ENDPOINT=
```

---

## 6. Start Backend

```
npm run dev
```

---

## 7. Start Flutter

```
flutter run
```

---

# Branch Strategy

Never work directly on

```
main
```

Create feature branches.

Example

```
feature/auth

feature/feed

feature/chat

feature/clubs

feature/career
```

Bug fixes

```
bugfix/login

bugfix/profile
```

---

# Commit Messages

Follow Conventional Commits.

Examples

```
feat(auth): add JWT login

fix(feed): resolve duplicate posts

docs: update API documentation

refactor(chat): improve socket handling

style(ui): update profile screen

test(auth): add login tests
```

---

# Pull Request Process

Before opening a PR:

- Pull latest `develop`
- Resolve conflicts
- Run tests
- Update documentation
- Verify UI
- Check coding standards

PR Title Example

```
feat(feed): add post bookmarking
```

Every Pull Request should include:

- Summary
- Screenshots (if UI changes)
- Related Issue
- Testing Notes

---

# Issue Guidelines

When reporting a bug include:

- Description
- Steps to reproduce
- Expected result
- Actual result
- Device
- OS
- Screenshots
- Logs (if available)

---

# Feature Requests

Before requesting a feature:

- Search existing issues.
- Explain the problem.
- Explain the proposed solution.
- Describe the expected user experience.

---

# Coding Standards

Flutter

- Feature-first architecture
- Riverpod
- GoRouter
- Repository Pattern
- No business logic in widgets

Backend

- Modular architecture
- Service layer
- Repository layer
- Zod validation
- Prisma ORM

---

# Documentation

Every major feature should update:

- PRD
- API Specification
- User Flows
- Changelog (if applicable)

Documentation is part of the feature—not an afterthought.

---

# Testing

Before submitting:

Flutter

```
flutter analyze

flutter test
```

Backend

```
npm run lint

npm run test
```

All tests should pass.

---

# Code Review Checklist

Reviewers should verify:

- Readable code
- Correct architecture
- Error handling
- Validation
- Security
- Performance
- Documentation updates
- Tests

---

# Security

Do not commit:

- API Keys
- Database passwords
- Firebase credentials
- Secrets

Use environment variables.

---

# Good First Issues

Ideal for new contributors:

- Improve documentation
- Fix UI bugs
- Improve accessibility
- Refactor widgets
- Add tests
- Update translations

These issues should be labeled:

```
good first issue
```

---

# Labels

Suggested GitHub labels:

- bug
- enhancement
- documentation
- feature
- help wanted
- good first issue
- ui
- backend
- frontend
- database
- api
- security

---

# Discussions

Use GitHub Discussions for:

- Ideas
- Questions
- Architecture
- Roadmap
- Community support

Avoid using issues for general discussions.

---

# License

By contributing to CampusHub, you agree that your contributions will be licensed under the project's open-source license.

---

# Thank You

Every contribution—whether it's a typo fix, a design improvement, or a major feature—helps CampusHub become a better platform for students and educators.

Thank you for being part of the CampusHub community.

🚀 Happy Coding!
