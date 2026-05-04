# LMS API Documentation

**Base URL:** `https://your-domain.com/api`

> Runtime mode: Moodle-only. Local DB-backed account creation and content writes are disabled.

---

## Authentication

### Register
```
POST /api/auth/register
Content-Type: application/json

{
  "name": "John Doe",
  "username": "john.doe",
  "email": "john@example.com",
  "password": "SecurePass123"
}

Response 200:
{
  "message": "Verification code sent to your email. Please check your inbox.",
  "email": "john@example.com",
  "username": "john.doe",
  "otpSent": true
}
```

### Verify OTP
```
POST /api/auth/verify-otp
Content-Type: application/json

{
  "email": "john@example.com",
  "otp": "123456"
}

Response 201:
{
  "message": "Registration successful",
  "token": "jwt_token_here",
  "user": {
    "id": "moodle-123",
    "name": "John Doe",
    "username": "john.doe",
    "email": "john@example.com",
    "role": "student",
    "moodleId": 123
  }
}
```

### Login
```
POST /api/auth/login
Content-Type: application/json

{
  "identifier": "john.doe",
  "password": "SecurePass123"
}

Response 200:
{
  "message": "Login successful",
  "token": "jwt_token_here",
  "user": {
    "id": "moodle-123",
    "name": "John Doe",
    "username": "john.doe",
    "email": "john@example.com",
    "role": "student",
    "moodleId": 123
  }
}
```

---

## Users

All user routes require `Authorization: Bearer <token>`.

### Get Profile
```
GET /api/users/me
Response 200: { "user": { ... } }
```

### Update Profile
```
PUT /api/users/me
Content-Type: application/json
{ "name": "New Name" }
Response 200: { "message": "Profile updated", "user": { ... } }
```

### List Users (Admin Only)
```
GET /api/users?page=1&limit=20
Response 200: { "users": [...], "pagination": { ... } }
```

---

## Courses

### List Courses (Public)
```
GET /api/courses?page=1&limit=20
Response 200: { "courses": [...], "pagination": { ... } }
```

### Get Course Detail (Public, optional auth for enrollment status)
```
GET /api/courses/:id
Response 200: { "course": { ... }, "isEnrolled": false, "lessonCount": 5 }
```

### Create Course (Admin)
```
POST /api/courses
Authorization: Bearer <admin_token>
Content-Type: application/json

{ "title": "Physics 101", "description": "...", "price": 499, "thumbnail_url": "..." }
Response 201: { "message": "Course created", "course": { ... } }
```

### Update Course (Admin)
```
PUT /api/courses/:id
Authorization: Bearer <admin_token>
Content-Type: application/json
{ "title": "Updated Title", "price": 599 }
```

### Delete Course (Admin)
```
DELETE /api/courses/:id
Authorization: Bearer <admin_token>
Response 200: { "message": "Course deleted" }
```

---

## Lessons

All lesson routes require authentication.

### List Lessons (Enrolled/Admin)
```
GET /api/courses/:courseId/lessons
Authorization: Bearer <token>
Response 200: { "lessons": [...] }
```

### Get Lesson with Signed URL (Enrolled/Admin)
```
GET /api/lessons/:id
Authorization: Bearer <token>
Response 200: { "lesson": { ..., "signed_url": "https://..." } }
```

### Create Lesson (Admin)
```
POST /api/courses/:courseId/lessons
Authorization: Bearer <admin_token>
Content-Type: multipart/form-data

file: <video or pdf file>
title: "Lesson Title"
sort_order: 1

Response 201: { "message": "Lesson created", "lesson": { ... } }
```

### Update Lesson (Admin)
```
PUT /api/lessons/:id
Authorization: Bearer <admin_token>
Content-Type: multipart/form-data
title: "Updated Title"
file: <optional new file>
```

### Delete Lesson (Admin)
```
DELETE /api/lessons/:id
Authorization: Bearer <admin_token>
Response 200: { "message": "Lesson deleted" }
```

---

## Enrollments

### Enroll in Course
```
POST /api/courses/:courseId/enroll
Authorization: Bearer <token>
Response 201: { "message": "Enrolled successfully", "enrollment": { ... } }
```

### List My Enrollments
```
GET /api/enrollments
Authorization: Bearer <token>
Response 200: { "enrollments": [{ ..., "course": { ... } }] }
```

---

## Health Check
```
GET /api/health
Response 200: { "status": "OK", "timestamp": "..." }
```

---

## Error Responses

All errors follow this format:
```json
{ "error": "Error message here" }
```

| Status | Meaning |
|--------|---------|
| 400 | Bad request / validation error |
| 401 | Unauthorized / invalid token |
| 403 | Forbidden / insufficient permissions |
| 404 | Not found |
| 409 | Conflict (duplicate) |
| 429 | Too many requests |
| 500 | Internal server error |
