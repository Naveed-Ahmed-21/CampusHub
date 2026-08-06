# 🚀 CampusHub API Specification

**Version:** 1.0.0  
**API Version:** v1  
**Protocol:** REST API  
**Authentication:** JWT + Refresh Token  
**Response Format:** JSON

---

# Table of Contents

1. API Standards
2. Authentication
3. Response Format
4. Error Handling
5. Authentication APIs
6. User APIs
7. Department APIs
8. Feed APIs
9. Club APIs
10. Chat APIs
11. Career APIs
12. Event APIs
13. Placement APIs
14. Portfolio APIs
15. Notification APIs
16. Admin APIs

---

# Base URL

Development

```
http://localhost:3000/api/v1
```

Production

```
https://api.campushub.app/api/v1
```

---

# Authentication

Protected APIs require

```
Authorization: Bearer <access_token>
```

---

# Standard Response Format

Success

```json
{
  "success": true,
  "message": "Success",
  "data": {}
}
```

Error

```json
{
  "success": false,
  "message": "Invalid Credentials",
  "errors": []
}
```

---

# HTTP Status Codes

| Code | Meaning |
|------|---------|
|200|Success|
|201|Created|
|400|Bad Request|
|401|Unauthorized|
|403|Forbidden|
|404|Not Found|
|409|Conflict|
|422|Validation Error|
|500|Internal Server Error|

---

# AUTH MODULE

## Register

POST

```
/auth/register
```

Body

```json
{
  "email": "",
  "password": "",
  "departmentId": "",
  "role": "STUDENT"
}
```

---

## Login

POST

```
/auth/login
```

Returns

```json
{
  "accessToken": "",
  "refreshToken": "",
  "user": {}
}
```

---

## Refresh Token

POST

```
/auth/refresh
```

---

## Logout

POST

```
/auth/logout
```

---

## Forgot Password

POST

```
/auth/forgot-password
```

---

## Reset Password

POST

```
/auth/reset-password
```

---

# USER MODULE

## Get Current User

GET

```
/users/me
```

---

## Update Profile

PUT

```
/users/me
```

---

## Upload Profile Image

POST

```
/users/profile-photo
```

---

## Search Users

GET

```
/users/search?q=
```

---

# DEPARTMENT MODULE

## Get Departments

GET

```
/departments
```

---

## Get Related Departments

GET

```
/departments/{id}/related
```

---

# FEED MODULE

## Get My Feed

GET

```
/feed/my
```

---

## Get Related Feed

GET

```
/feed/related
```

---

## Get Cross Feed

GET

```
/feed/cross
```

---

## Get Club Feed

GET

```
/feed/clubs
```

---

## Create Post

POST

```
/posts
```

Body

```json
{
    "title":"",
    "content":"",
    "visibility":"DEPARTMENT"
}
```

---

## Update Post

PUT

```
/posts/{id}
```

---

## Delete Post

DELETE

```
/posts/{id}
```

---

## Like Post

POST

```
/posts/{id}/like
```

---

## Unlike Post

DELETE

```
/posts/{id}/like
```

---

## Comment

POST

```
/posts/{id}/comments
```

---

## Save Post

POST

```
/posts/{id}/save
```

---

# CLUB MODULE

## Get Clubs

GET

```
/clubs
```

---

## Club Details

GET

```
/clubs/{id}
```

---

## Create Club

POST

```
/clubs
```

---

## Update Club

PUT

```
/clubs/{id}
```

---

## Join Club

POST

```
/clubs/{id}/join
```

---

## Leave Club

DELETE

```
/clubs/{id}/leave
```

---

## Approve Member

POST

```
/clubs/{id}/members/{userId}
```

---

## Club Members

GET

```
/clubs/{id}/members
```

---

## Club Posts

GET

```
/clubs/{id}/posts
```

---

# CHAT MODULE

## Chat List

GET

```
/chat
```

---

## Messages

GET

```
/chat/{roomId}/messages
```

---

## Send Message

POST

```
/chat/{roomId}/messages
```

---

## Upload Attachment

POST

```
/chat/upload
```

---

# CAREER HUB

## Get Roadmaps

GET

```
/career/roadmaps
```

---

## Roadmap Details

GET

```
/career/roadmaps/{id}
```

---

## Resources

GET

```
/career/topics/{id}/resources
```

---

## Update Progress

POST

```
/career/progress
```

---

## Student Progress

GET

```
/career/progress
```

---

# EVENTS

## Events

GET

```
/events
```

---

## Event Details

GET

```
/events/{id}
```

---

## Register Event

POST

```
/events/{id}/register
```

---

## Cancel Registration

DELETE

```
/events/{id}/register
```

---

# PLACEMENT

## Company Drives

GET

```
/placements
```

---

## Drive Details

GET

```
/placements/{id}
```

---

## Apply

POST

```
/placements/{id}/apply
```

---

## My Applications

GET

```
/placements/applications
```

---

# PORTFOLIO

## Portfolio

GET

```
/portfolio
```

---

## Update Portfolio

PUT

```
/portfolio
```

---

## Upload Certificate

POST

```
/portfolio/certificates
```

---

## Upload Resume

POST

```
/portfolio/resume
```

---

# NOTIFICATIONS

## Notifications

GET

```
/notifications
```

---

## Mark Read

PATCH

```
/notifications/{id}/read
```

---

## Mark All Read

PATCH

```
/notifications/read-all
```

---

# SEARCH

Global Search

GET

```
/search?q=
```

Returns

- Students
- Faculty
- Clubs
- Posts
- Events
- Resources

---

# ADMIN

## Dashboard

GET

```
/admin/dashboard
```

---

## Users

GET

```
/admin/users
```

---

## Update User

PUT

```
/admin/users/{id}
```

---

## Verify Club

PATCH

```
/admin/clubs/{id}/verify
```

---

## Reports

GET

```
/admin/reports
```

---

# Pagination

```
?page=1&limit=20
```

Example

```
GET /posts?page=2&limit=10
```

---

# Sorting

```
?sort=createdAt
```

```
?order=desc
```

---

# Filtering

```
?department=IT
```

```
?club=FOSS
```

```
?category=Workshop
```

---

# File Upload

Supported

- Images
- PDF
- DOCX

Multipart

```
multipart/form-data
```

---

# Security

- JWT Authentication
- Refresh Tokens
- HTTPS
- Password Hashing (bcrypt)
- Role-Based Access Control
- Request Validation
- Rate Limiting

---

# API Versioning

```
/api/v1/
```

Future

```
/api/v2/
```

---

# Version 2 APIs

- Assignment Management
- Attendance
- Timetable
- Marketplace
- Lost & Found
- Innovation Hub
- Alumni

---

# Version 3 APIs

- AI Career Coach
- AI Resume Review
- AI Study Assistant
- Recommendation Engine
- Multi-College Support

---

# Conclusion

CampusHub APIs are designed around modular feature domains rather than monolithic endpoints. Every module (Authentication, Feed, Clubs, Career, Placement, etc.) exposes a consistent REST interface with standardized responses, authentication, pagination, filtering, and error handling. This makes the backend easier to maintain and allows frontend and backend teams to work independently using a stable API contract.
