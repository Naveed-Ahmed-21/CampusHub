# 📜 Changelog

All notable changes to **CampusHub** will be documented in this file.

This project follows:

- [Keep a Changelog](https://keepachangelog.com/)
- [Semantic Versioning](https://semver.org/)

---

# [Unreleased]

## Added
- Docker End-to-End Orchestration
- Advanced ChatX Protocol

---

# [1.1.0] - 2026-08-16 - Faculty V1 Experience

## Added
### Backend
- Dedicated Faculty module with Prisma models: `Subject`, `SubjectResource`, `SubjectAnnouncement`, `SubjectEnrollment`, `StudentMentorship`
- Faculty dashboard aggregation (`/api/v1/faculty/dashboard`), assigned subjects management, ImageKit study material uploads, academic announcements publishing, today class timetable, and student mentorship roster
- Role-based access control (RBAC) protecting endpoints with `requireAuth()` and `requireRole('FACULTY', ...)`
- Comprehensive unit and integration test suite with 10 passing tests

### Flutter Frontend (`apps/campus_hub_app`)
- Dedicated Faculty experience combining Academic Workspace + Campus Social Stream + Communication
- `FacultyHomeView` with welcome header, today's schedule card, quick actions bar, KPI metrics, and embedded department feeds
- `FacultyTeachingView` with 3 tabs: My Subjects grid, Timetable, and Student Mentoring roster
- `SubjectDetailView` with 4 tabs: Course Overview & Syllabus, ImageKit Study Materials with uploader dialog, Announcements publisher, and Enrolled Students
- `FacultyCampusView` with department/cross-department feeds, events, QR attendance scanner dialog, and club advisor integration
- `FacultyProfileView` displaying designation, academic publications, research interests, office hours, and settings
- GoRouter adaptive role navigation and route guards for `isFaculty`
- User Flows
- Database Design
- API Specification
- System Architecture
- UI Design Guidelines
- Development Roadmap
- Contribution Guide
- Coding Standards
- Security Policy
- Deployment Guide
- Testing Guide

---

## Changed

- None

---

## Fixed

- None

---

## Removed

- None

---

# [1.0.0] - Initial MVP

## Added

### Authentication

- Student login
- Faculty login
- Placement Officer login
- Admin login
- JWT authentication
- Refresh token support
- Password reset

---

### User Profiles

- Profile creation
- Profile editing
- Skills
- Portfolio links
- Resume upload

---

### Feed

- Department feed
- Related department feed
- Cross-department feed
- Club feed
- Following feed
- Post creation
- Likes
- Comments
- Save posts

---

### Clubs

- Create clubs
- Join clubs
- Club verification
- Club feed
- Club events
- Club resources

---

### Chat

- Personal chat
- Club chat
- Department chat
- Image sharing
- Document sharing

---

### Career Hub

- Career roadmaps
- Progress tracking
- Learning resources
- Weekly goals

---

### Events

- College events
- Department events
- Club events
- Event registration

---

### Placement

- Placement drives
- Eligibility
- Apply
- Application tracking

---

### Portfolio

- Projects
- Certificates
- Achievements
- Skills

---

### Notifications

- Push notifications
- Notification center
- Read status

---

## Security

- JWT authentication
- Password hashing
- Role-Based Access Control
- HTTPS support
- Input validation
- Rate limiting

---

## Developer Experience

- Feature-first Flutter architecture
- Modular backend architecture
- Prisma ORM
- PostgreSQL
- Docker support
- GitHub Actions

---

# [1.1.0] - Planned

## Added

- Academic resources
- Classroom module
- Resource categories
- Improved search
- Better notifications

---

## Changed

- Feed performance improvements
- UI enhancements

---

# [1.2.0] - Planned

## Added

- Assignment module
- Attendance
- Timetable
- Internal marks
- Calendar

---

# [2.0.0] - Planned

## Added

### Innovation Hub

- Startup ideas
- Team finder
- Project recruitment
- Research collaboration

---

### Marketplace

- Student marketplace
- Buy & Sell

---

### Lost & Found

- Lost items
- Found items

---

### Advanced Search

- Global indexing
- Better filtering

---

# [3.0.0] - Planned

## Added

### Artificial Intelligence

- AI Career Coach
- AI Resume Review
- AI Study Assistant
- AI Notes Generator

---

### Recommendations

- Personalized learning
- Career suggestions
- Event recommendations
- Club recommendations

---

# [4.0.0] - Planned

## Added

### Multi-College Platform

- Multiple campuses
- College administration
- Shared communities

---

### Alumni Network

- Alumni directory
- Mentorship
- Networking

---

### Industry Integration

- Recruiter portal
- Company profiles
- Internship management

---

# Version History

| Version | Status | Description |
|----------|--------|-------------|
| Unreleased | 🚧 | Current development |
| 1.0.0 | 🎯 | Initial MVP |
| 1.1.0 | 📋 | Academic improvements |
| 1.2.0 | 📋 | Student productivity |
| 2.0.0 | 📋 | Innovation Hub |
| 3.0.0 | 📋 | AI Platform |
| 4.0.0 | 📋 | Multi-college ecosystem |

---

# Release Process

Before each release:

- Update version number
- Update this changelog
- Tag the release in Git
- Publish release notes
- Deploy the application

Example:

```bash
git tag v1.0.0
git push origin v1.0.0
```

---

# Semantic Versioning

CampusHub follows Semantic Versioning:

```
MAJOR.MINOR.PATCH
```

Examples:

```
1.0.0

1.0.1

1.1.0

2.0.0
```

Meaning:

- **MAJOR** – Breaking changes
- **MINOR** – New backward-compatible features
- **PATCH** – Bug fixes and small improvements

---

# Contribution

When submitting a Pull Request that changes functionality:

- Add an entry under **Unreleased**
- Use the appropriate section:
  - Added
  - Changed
  - Fixed
  - Removed

Maintainers will move entries from **Unreleased** into the next version during a release.

---

# Acknowledgements

Thank you to every contributor who helps improve CampusHub.

Every feature, bug fix, documentation update, and design improvement contributes to making CampusHub a better platform for students, faculty, and institutions.
