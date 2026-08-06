# 🚀 CampusHub User Flows

**Version:** 1.0

**Project:** CampusHub

**Last Updated:** August 2026

---

# Overview

This document describes how different users navigate through CampusHub.

User Roles

- Student
- Faculty
- Placement Officer
- Administrator

---

# Student Journey

```text
Open App
      │
      ▼
Splash Screen
      │
      ▼
Check Authentication
      │
 ┌────┴────┐
 │         │
No Token   Valid Token
 │         │
 ▼         ▼
Login    Home
```

---

# Login Flow

```text
Open App

↓

Login

↓

Enter College Email / Roll Number

↓

Enter Password

↓

Authentication

↓

Success

↓

Home Screen

↓

Load User Profile
```

Forgot Password

```text
Forgot Password

↓

Enter College Email

↓

Receive OTP

↓

Verify OTP

↓

Create New Password

↓

Login
```

---

# Onboarding Flow (First Login)

```text
Login

↓

Complete Profile

↓

Select Department

↓

Select Interests

↓

Choose Career Goals

↓

Join Suggested Clubs

↓

Go to Home
```

Students choose interests such as:

- Flutter
- AI
- Cyber Security
- DevOps
- UI/UX
- Cloud
- Robotics

This helps personalize the feed and Career Hub.

---

# Home Flow

```text
Home

↓

My Feed

↓

Related Feed

↓

Cross Feed

↓

Club Feed

↓

Following Feed
```

Students can switch between feed types at any time.

---

# Feed Flow

```text
Home Feed

↓

Open Post

↓

Like

↓

Comment

↓

Share

↓

Save

↓

Report
```

Students can also:

```text
Create Post

↓

Write Text

↓

Attach Images/PDF

↓

Choose Visibility

↓

Publish
```

Visibility options:

- Department
- Related Departments
- Entire College
- Club

---

# Department Feed

```text
Department Feed

↓

View Announcements

↓

Notes

↓

Department Events

↓

Projects
```

Example

IT Students see

- IT
- CSE
- AI & DS (Related Feed)

---

# Club Flow

```text
Discover Clubs

↓

Open Club

↓

View Details

↓

Join Club

↓

Become Member
```

Club Owner

```text
Create Club

↓

Fill Details

↓

Upload Logo

↓

Submit Verification

↓

Admin Review

↓

Approved

↓

Club Published
```

Club Members

```text
Club

↓

Posts

↓

Events

↓

Resources

↓

Discussions

↓

Members
```

---

# Chat Flow

```text
Messages

↓

Open Chat

↓

Send Message

↓

Receive Reply
```

Attachments

```text
Send

↓

Image

PDF

Document
```

Types

- Personal
- Club
- Department

---

# Career Hub Flow

```text
Career Hub

↓

Choose Career Path

↓

Open Roadmap

↓

Learn Topic

↓

Complete Topic

↓

Update Progress

↓

Unlock Next Level
```

Each Topic

```text
Topic

↓

Documentation

↓

Video

↓

Practice

↓

Mini Project

↓

Mark Complete
```

---

# Portfolio Flow

```text
Profile

↓

Portfolio

↓

Projects

↓

Certificates

↓

Achievements

↓

Skills

↓

Resume
```

Students can upload

- Resume
- Certificates
- Project Links

---

# Events Flow

```text
Events

↓

View Event

↓

Register

↓

Receive Confirmation

↓

Attend Event
```

Categories

- College
- Department
- Club

---

# Search Flow

```text
Search

↓

Enter Keyword

↓

Results

Students

Faculty

Clubs

Posts

Events

Resources
```

---

# Notifications Flow

```text
Notification

↓

Open Notification

↓

Redirect

↓

Related Screen
```

Examples

Message

↓

Open Chat

Event

↓

Open Event

Club

↓

Open Club

---

# Placement Flow

```text
Placement

↓

Company Drives

↓

View Details

↓

Check Eligibility

↓

Apply

↓

Application Submitted
```

Students can also

- Track Status
- View Results

---

# Innovation Hub Flow (Version 2)

```text
Ideas

↓

Open Idea

↓

Join Project

↓

Team Chat

↓

Build Project
```

---

# Faculty Flow

```text
Login

↓

Dashboard

↓

Create Classroom

↓

Upload Notes

↓

Post Announcement

↓

Interact With Students
```

Faculty can

- Create Posts
- Share Resources
- Manage Classroom

---

# Placement Officer Flow

```text
Login

↓

Placement Dashboard

↓

Create Company Drive

↓

Eligibility

↓

Registration

↓

Publish Results
```

---

# Admin Flow

```text
Login

↓

Dashboard

↓

Manage Users

↓

Verify Clubs

↓

Manage Departments

↓

Analytics
```

---

# Feed Logic

## My Feed

Shows only

- Own Department

---

## Related Feed

Shows

Example

IT

↓

IT

↓

CSE

↓

AI & DS

Mappings are configurable by the Administrator.

---

## Cross Feed

Shows

All Departments

---

## Club Feed

Shows

Joined Clubs

---

## Following Feed

Shows content from

- Faculty
- Clubs
- Seniors
- Alumni (Future)

---

# Cross Department Collaboration

Students create projects.

Example

```text
Smart Agriculture Robot

Need

Flutter Developer

Mechanical Engineer

Embedded Engineer

Backend Developer
```

Interested students request to join.

Project owner accepts members.

---

# Club Collaboration

Clubs are not department-specific.

Example

FOSS Club

Members

- IT
- CSE
- AI & DS
- ECE
- EEE
- Mechanical
- Civil
- Automobile

Every student can join.

---

# User Journey Summary

## Student

```text
Register

↓

Complete Profile

↓

Explore Feed

↓

Join Clubs

↓

Chat

↓

Follow Roadmaps

↓

Build Portfolio

↓

Apply for Placements

↓

Graduate
```

---

## Faculty

```text
Login

↓

Classrooms

↓

Resources

↓

Announcements

↓

Student Interaction
```

---

## Placement Officer

```text
Company

↓

Eligibility

↓

Registration

↓

Results
```

---

## Administrator

```text
Users

↓

Departments

↓

Clubs

↓

Reports

↓

Analytics
```

---

# Flow Design Principles

CampusHub follows these principles:

- Simple navigation
- Minimal clicks
- Consistent layouts
- Role-based access
- Mobile-first design
- Personalized content
- Scalable architecture
- Fast access to important features

---

# Conclusion

CampusHub is designed to provide a seamless journey for every user—from a student's first login to graduation. Every flow is built around reducing friction, encouraging collaboration, and supporting academic and career growth while keeping navigation intuitive and role-based.
