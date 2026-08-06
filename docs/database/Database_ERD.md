# 🗄️ CampusHub Database Design (ERD)

**Version:** 1.0

**Project:** CampusHub

**Database:** PostgreSQL

**ORM:** Prisma

---

# Overview

CampusHub follows a relational database architecture using PostgreSQL.

The database is modular, normalized, and designed to support:

- Single College
- Multiple Departments
- Multiple User Roles
- Clubs
- Career Roadmaps
- Social Feed
- Messaging
- Events
- Placements
- Notifications
- Future Multi-College Expansion

---

# Database Design Principles

- UUID Primary Keys
- Soft Deletes
- Audit Fields
- Foreign Key Constraints
- Normalized Tables
- Scalable Relationships

Every table contains

createdAt

updatedAt

deletedAt (nullable)

---

# Core Entities

Campus

↓

Department

↓

User

↓

Role

↓

Profile

---

# Entity Relationship Diagram

```text
Campus

│

├── Departments

│

├── Users

│

├── Clubs

│

├── Events

│

└── Placement Drives
```

---

# Users

Stores every authenticated user.

Fields

- id (UUID)
- roleId
- departmentId
- email
- password
- status
- createdAt
- updatedAt

Relationship

User

↓

Profile

↓

Posts

↓

Messages

↓

Notifications

↓

Portfolio

---

# Roles

Application Roles

- Student
- Faculty
- Placement Officer
- Admin

Relationship

Role

↓

Many Users

---

# Departments

Fields

- id
- name
- shortName
- description

Examples

- IT
- CSE
- AI & DS
- Civil
- Mechanical
- ECE
- EEE
- Automobile

Relationship

Department

↓

Users

↓

Posts

↓

Resources

↓

Events

---

# Department Relations

Supports related feeds.

Example

IT

↓

Related

↓

CSE

↓

AI & DS

Table

DepartmentRelations

Fields

departmentId

relatedDepartmentId

---

# Profiles

Stores public information.

Fields

- userId
- bio
- profilePhoto
- skills
- github
- linkedin
- portfolio
- resume

Relationship

One User

↓

One Profile

---

# Posts

Fields

- id
- authorId
- visibility
- departmentId
- clubId
- title
- content
- createdAt

Visibility

- Department
- Related
- Cross
- Club

Relationship

Post

↓

Comments

↓

Likes

↓

Media

---

# Comments

Fields

- id
- postId
- userId
- content

Relationship

One Post

↓

Many Comments

---

# Likes

Fields

- id
- postId
- userId

Relationship

One User

↓

Many Likes

---

# Saved Posts

Allows bookmarking.

Fields

- userId
- postId

---

# Clubs

Fields

- id
- name
- description
- ownerId
- category
- logo

Categories

Technical

Cultural

Sports

Community

Relationship

Club

↓

Members

↓

Posts

↓

Events

↓

Resources

---

# Club Members

Fields

- userId
- clubId
- role

Roles

Owner

Manager

Member

---

# Club Requests

Stores join requests.

Fields

- userId
- clubId
- status

Status

Pending

Approved

Rejected

---

# Chat Rooms

Fields

- id
- type

Types

Personal

Department

Club

Project

---

# Messages

Fields

- id
- chatRoomId
- senderId
- message
- attachment

Relationship

Chat Room

↓

Messages

---

# Career Roadmaps

Fields

- id
- title
- category
- description

Examples

Flutter

AI

Cloud

DevOps

Cyber Security

---

# Roadmap Topics

Fields

- roadmapId
- title
- order

Relationship

Roadmap

↓

Topics

---

# Resources

Fields

- title
- type
- url

Types

Video

Documentation

Article

GitHub

Book

Practice

Relationship

Topic

↓

Resources

---

# Student Progress

Tracks roadmap progress.

Fields

- userId
- topicId
- completed

Relationship

User

↓

Roadmap Progress

---

# Projects

Innovation Hub

Fields

- ownerId
- title
- description
- status

Status

Recruiting

Building

Completed

---

# Project Members

Fields

- projectId
- userId
- role

---

# Events

Fields

- title
- organizer
- departmentId
- clubId

Types

College

Department

Club

---

# Event Registration

Fields

- eventId
- userId

---

# Placement Drives

Fields

- company
- eligibility
- package
- deadline

---

# Placement Applications

Fields

- driveId
- studentId
- status

Status

Applied

Shortlisted

Interview

Selected

Rejected

---

# Portfolio

Fields

- userId
- headline
- about

Contains

Projects

Certificates

Achievements

Skills

---

# Certificates

Fields

- userId
- title
- issuer

---

# Achievements

Fields

- userId
- achievement

Examples

Hackathon Winner

Research Paper

Internship

Open Source Contributor

---

# Notifications

Fields

- receiverId
- type
- title
- isRead

Types

Message

Event

Club

Placement

Career

Announcement

---

# Search Index

Future

Supports

Students

Faculty

Resources

Events

Projects

---

# Future Tables

Attendance

Assignments

Timetable

Marketplace

LostFound

Alumni

Research

AIChat

Mentorship

VideoMeetings

---

# Relationships Summary

Campus

↓

Departments

↓

Users

↓

Profiles

↓

Posts

↓

Comments

↓

Likes

↓

Notifications

Users

↓

Clubs

↓

Messages

↓

Portfolio

↓

Career Progress

↓

Projects

↓

Placements

---

# Index Strategy

Create indexes for

- email
- departmentId
- clubId
- authorId
- roadmapId
- eventId
- createdAt

Composite Indexes

(userId, postId)

(clubId, userId)

(eventId, userId)

---

# Soft Delete Strategy

Every major table contains

deletedAt

Instead of deleting records permanently.

---

# Naming Convention

Tables

snake_case

Example

placement_drives

Columns

camelCase inside Prisma

Database

snake_case

Primary Keys

UUID

Foreign Keys

tableId

Example

departmentId

clubId

userId

---

# Estimated Database Size

Version 1

15–20 Tables

Version 2

30+ Tables

Version 3

50+ Tables

---

# Conclusion

The CampusHub database is designed around modular entities rather than isolated features. This allows new capabilities—such as attendance, AI assistants, alumni, or multi-college support—to be added without redesigning the core schema. The focus is on maintainability, scalability, and clean relationships that support long-term growth.
