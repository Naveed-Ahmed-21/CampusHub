# ❓ CampusHub Frequently Asked Questions (FAQ)

**Project:** CampusHub

**Version:** 1.0

---

# General

## What is CampusHub?

CampusHub is an open-source digital campus ecosystem designed to connect students, faculty, placement officers, and administrators through a single platform.

It combines:

* Academic collaboration
* Social communication
* Career development
* Clubs
* Events
* Placements
* Student portfolios

---

## Who is CampusHub for?

CampusHub is designed for:

* Students
* Faculty
* Placement Officers
* College Administrators

Future versions will also support:

* Alumni
* Recruiters
* Industry Mentors

---

## Is CampusHub open source?

Yes.

CampusHub is an open-source project and welcomes community contributions.

Please read:

* CONTRIBUTING.md
* CODE_OF_CONDUCT.md
* SECURITY.md

before contributing.

---

## Which license does CampusHub use?

CampusHub uses the **MIT License**.

See the `LICENSE` file for details.

---

# Development

## Which technologies are used?

Frontend

* Flutter
* Dart

Backend

* Node.js
* Express.js
* TypeScript

Database

* PostgreSQL
* Prisma ORM

Other Services

* Socket.IO
* Firebase Cloud Messaging
* Cloudinary

---

## Why Flutter?

Flutter allows us to build high-performance cross-platform applications using a single codebase.

Benefits include:

* Fast development
* Native performance
* Excellent UI
* Strong community support

---

## Why PostgreSQL?

PostgreSQL provides:

* ACID compliance
* Strong relational modeling
* Excellent performance
* Scalability
* Open-source licensing

---

## Why Prisma?

Prisma provides:

* Type-safe queries
* Database migrations
* Excellent developer experience
* Strong TypeScript integration

---

## Why Node.js?

Node.js is well suited for:

* REST APIs
* Real-time communication
* Socket.IO
* Fast development
* Large ecosystem

---

# Architecture

## Why a Modular Monolith?

Version 1 uses a Modular Monolith because it is:

* Easier to develop
* Easier to debug
* Easier to deploy

If CampusHub grows significantly, individual modules can later be extracted into microservices.

---

## Why Feature-First Architecture in Flutter?

Feature-first organization keeps related code together.

Instead of grouping files by type, each feature owns its:

* UI
* Business logic
* Repository
* Providers
* Models

This scales better as the project grows.

---

## Why REST instead of GraphQL?

REST is:

* Simpler for contributors
* Easier to document
* Widely understood
* Well suited to the initial scope of CampusHub

GraphQL can be evaluated in future versions if there is a clear need.

---

# Features

## Can students create clubs?

Yes.

Students can create clubs.

New clubs require administrator verification before becoming publicly available.

---

## Can clubs include multiple departments?

Yes.

Clubs are cross-department by design.

For example:

* IT
* CSE
* AI & DS
* ECE
* Mechanical

can all belong to the same club.

---

## How does the feed work?

CampusHub provides multiple feed types:

* My Feed
* Related Department Feed
* Cross-Department Feed
* Club Feed
* Following Feed

Users can switch between them at any time.

---

## Why are IT, CSE, and AI & DS grouped together?

Related departments share many common topics.

Students can:

* View related technical content
* Switch to Cross Feed to view content from all departments

Department relationships are configurable by administrators.

---

## What is the Career Hub?

Career Hub provides:

* Career roadmaps
* Learning resources
* Progress tracking
* Mini projects
* Career guidance

It helps students prepare for placements and internships.

---

## Can users upload resumes?

Yes.

Students can upload:

* Resume
* Certificates
* Project links
* Portfolio information

---

# Security

## How are passwords stored?

Passwords are hashed using bcrypt before being stored.

Plain-text passwords are never stored.

---

## What authentication is used?

CampusHub uses:

* JWT Access Tokens
* Refresh Tokens

---

## Is HTTPS required?

Yes.

Production deployments should always use HTTPS.

---

# Database

## Which database is used?

PostgreSQL.

---

## Which ORM is used?

Prisma ORM.

---

## Why UUID instead of auto-increment IDs?

UUIDs:

* Are globally unique
* Support distributed systems
* Reduce predictable identifiers

---

# Deployment

## Can CampusHub run locally?

Yes.

You can run:

* PostgreSQL
* Backend
* Flutter

entirely on your local machine.

---

## Is Docker supported?

Yes.

Docker and Docker Compose are recommended for local development and production deployment.

---

## Which operating systems are supported?

Development is supported on:

* Linux
* Windows
* macOS

---

# Contributing

## I'm new to open source. Can I contribute?

Absolutely.

Look for issues labeled:

* `good first issue`
* `help wanted`

Documentation, testing, and UI improvements are great starting points.

---

## How do I report a bug?

Create a GitHub Issue with:

* Description
* Steps to reproduce
* Expected result
* Actual result
* Screenshots (if applicable)

Do not use public issues for security vulnerabilities.

---

## How do I request a feature?

Open a Feature Request issue and include:

* Problem statement
* Proposed solution
* Expected behavior

Maintainers will review the proposal.

---

## How do I submit code?

1. Fork the repository.
2. Create a feature branch.
3. Commit your changes.
4. Run tests.
5. Open a Pull Request.

---

# Versioning

## Which versioning system is used?

CampusHub follows Semantic Versioning.

Example:

```
1.0.0
```

Meaning:

* Major
* Minor
* Patch

---

# Roadmap

## What features are planned?

Future releases include:

* Assignments
* Attendance
* Timetable
* Innovation Hub
* AI Career Coach
* AI Resume Review
* Alumni Network
* Multi-college support

---

# Support

## Where can I ask questions?

Use:

* GitHub Discussions for questions and ideas
* GitHub Issues for bugs and feature requests
* Pull Requests for code contributions

---

# Still Have Questions?

If your question isn't answered here:

1. Check the project documentation.
2. Search existing GitHub Issues and Discussions.
3. Open a new Discussion if needed.

We welcome questions and feedback that help improve CampusHub and make it easier for others to contribute.

---

# Thank You

Thank you for your interest in CampusHub.

Whether you're reporting a bug, contributing code, improving documentation, or simply exploring the project, your involvement helps build a better digital campus ecosystem for everyone.
