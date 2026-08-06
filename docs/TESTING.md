# 🧪 CampusHub Testing Guide

**Project:** CampusHub

**Version:** 1.0

**Testing Strategy:** Shift Left Testing

---

# Table of Contents

1. Testing Philosophy
2. Testing Levels
3. Flutter Testing
4. Backend Testing
5. Database Testing
6. API Testing
7. Integration Testing
8. UI Testing
9. Security Testing
10. Performance Testing
11. Regression Testing
12. User Acceptance Testing
13. Release Checklist

---

# 1. Testing Philosophy

CampusHub follows the testing pyramid.

```
           UI Tests
        Integration Tests
          Unit Tests
```

Most tests should be **Unit Tests**.

---

# 2. Testing Levels

| Type | Purpose |
|------|---------|
| Unit | Individual functions |
| Widget | Flutter widgets |
| Integration | Flutter ↔ Backend |
| API | REST endpoints |
| Database | Prisma & PostgreSQL |
| Manual | User validation |
| UAT | Final acceptance |

---

# 3. Flutter Testing

## Unit Tests

Test:

- Services
- Repositories
- Helpers
- Utilities

Example

```
LoginService

FeedRepository

RoadmapRepository
```

Command

```bash
flutter test
```

---

## Widget Tests

Test

- Buttons
- Cards
- Navigation
- Forms

Command

```bash
flutter test
```

---

## Golden Tests (Optional)

Use for

- Feed Card
- Profile Card
- Club Card

Ensures UI doesn't change unexpectedly.

---

# 4. Backend Testing

Test

- Controllers
- Services
- Validation
- Repository layer

Command

```bash
npm test
```

---

# 5. Database Testing

Verify

- Migrations
- Relationships
- Constraints
- Cascade Rules
- Indexes

Test Cases

- Duplicate email
- Invalid foreign key
- Soft delete
- Transaction rollback

---

# 6. API Testing

Use

- Postman
- Bruno
- Insomnia

Test

### Authentication

- Register
- Login
- Refresh Token
- Logout

---

### Feed

- Create Post
- Edit
- Delete
- Like
- Comment

---

### Clubs

- Create Club
- Join
- Leave
- Member Approval

---

### Career

- Fetch Roadmaps
- Update Progress

---

### Placement

- View Drives
- Apply
- Status

---

# 7. Integration Testing

Verify

Flutter

↓

REST API

↓

Database

Examples

- Login flow
- Feed loading
- Club creation
- Chat messaging
- Event registration

---

# 8. UI Testing

Check

- Responsive layout
- Overflow
- Dark mode
- Loading states
- Empty states
- Error states

Devices

- Small Android
- Large Android
- Tablet (optional)

---

# 9. Security Testing

Verify

- JWT authentication
- Role permissions
- Password hashing
- Input validation
- Rate limiting
- SQL injection protection
- XSS prevention (web)

---

# 10. Performance Testing

Measure

- App startup time
- API response time
- Database query time
- Memory usage
- Image loading

Targets

| Metric | Goal |
|---------|------|
| API Response | < 500 ms (typical) |
| Login | < 2 sec |
| Feed Load | < 2 sec |
| Chat Delivery | < 500 ms |

---

# 11. Regression Testing

Before every release

Verify

- Login
- Feed
- Chat
- Clubs
- Career Hub
- Notifications
- Profile
- Placement

Nothing should break after new features.

---

# 12. User Acceptance Testing (UAT)

Invite

- Students
- Faculty
- Placement Officer

Tasks

- Register
- Login
- Join Club
- Create Post
- Send Message
- Follow Roadmap
- Register Event

Collect

- Bugs
- Suggestions
- UX feedback

---

# 13. Bug Severity

## Critical

Application crash

Authentication failure

Data loss

---

## High

Major feature broken

---

## Medium

Incorrect UI

Minor functionality issue

---

## Low

Typo

Alignment

Color inconsistency

---

# 14. Test Data

Use dedicated development data.

Examples

Students

```
student1@gceerode.edu.in

student2@gceerode.edu.in
```

Faculty

```
faculty@gceerode.edu.in
```

Never use production data for testing.

---

# 15. CI Testing

Every Pull Request should run

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

PRs should not be merged if checks fail.

---

# 16. Manual Testing Checklist

Authentication

- [ ] Register
- [ ] Login
- [ ] Forgot Password
- [ ] Logout

Feed

- [ ] Create Post
- [ ] Edit
- [ ] Delete
- [ ] Like
- [ ] Comment
- [ ] Save

Clubs

- [ ] Create Club
- [ ] Join
- [ ] Leave

Career

- [ ] Open Roadmap
- [ ] Complete Topic

Chat

- [ ] Send Message
- [ ] Receive Message
- [ ] Upload Attachment

Events

- [ ] Register
- [ ] Cancel Registration

Portfolio

- [ ] Upload Resume
- [ ] Add Certificate

Notifications

- [ ] Receive
- [ ] Mark Read

---

# 17. Release Checklist

Before Version 1.0

- [ ] Unit tests pass
- [ ] Widget tests pass
- [ ] Backend tests pass
- [ ] API tested
- [ ] Database verified
- [ ] Documentation updated
- [ ] No critical bugs
- [ ] APK generated
- [ ] Performance acceptable
- [ ] Security review completed

---

# 18. Recommended Tools

Flutter

- flutter_test
- integration_test
- mocktail

Backend

- Jest
- Supertest

API

- Bruno
- Postman

Performance

- Flutter DevTools

Crash Reporting

- Firebase Crashlytics

CI/CD

- GitHub Actions

---

# 19. Test Coverage Goals

| Area | Target |
|------|--------|
| Business Logic | 90%+ |
| API Layer | 80%+ |
| UI Widgets | 70%+ |
| Critical Flows | 100% |

Coverage is a guide—not a replacement for meaningful tests.

---

# Conclusion

Testing is a continuous activity throughout the development lifecycle. CampusHub aims to combine automated testing, manual validation, and user feedback to deliver a stable, secure, and maintainable platform. Every release should be backed by repeatable tests and a clear release checklist rather than relying solely on manual verification.
