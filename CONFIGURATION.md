# Environment Configuration Guide

## Overview
This guide explains how environment variables are configured across the backend and frontend of your LMS application.

## Backend Configuration (.env)

### Location
`/backend/.env`

### Key Variables

#### Server Settings
- `PORT`: Server port (default: 5000)
- `NODE_ENV`: Environment mode (development/production)
- `BASE_URL`: Full backend URL (e.g., http://localhost:5000)
- `CORS_ORIGIN`: Allowed origins for CORS (use * for development)

#### Authentication
- `JWT_SECRET`: Secret key for signing JWT tokens (keep secure!)
- `JWT_EXPIRES_IN`: Token expiration time (e.g., 7d)

#### Database
- No application database is used.
- User, course, lesson, and enrollment data are read from Moodle APIs.

#### Moodle Integration
- `MOODLE_URL`: Your Moodle site base URL
- `MOODLE_TOKEN`: Admin token with course management capabilities
- `MOODLE_COURSE_TOKEN`: Token for course operations
- `MOODLE_CREATE_USER_TOKEN`: Token for user creation
- `MOODLE_ENROL_TOKEN`: Token for enrollment operations

#### File Uploads
- `UPLOAD_DIR`: Directory for file uploads (default: uploads)
- `MAX_FILE_SIZE_MB`: Maximum file size in MB (default: 100)

### Security Notes
- ✅ `.env` is already in `.gitignore`
- ⚠️ Never commit `.env` to version control
- 🔒 Keep `JWT_SECRET` and all tokens secure
- 📝 Use `.env.example` as a template for team members

---

## Frontend Configuration (Flutter)

### Location
`/frontend/lib/config/api_config.dart`

### Key Constants

#### API Configuration
```dart
static const String baseUrl = 'http://localhost:5000/api';
```
**Update this for production!** Use your deployed backend URL.

#### Moodle Configuration
```dart
static const String moodleUrl = 'https://lms.premmcxtrainingacademy.com';
```

#### Enrollment Flow
The backend now enrolls users directly through Moodle after authentication.

---

## How to Use These Variables

### Backend (Node.js/Express)

Access environment variables using `process.env`:

```javascript
// Example: JWT authentication
const token = jwt.sign(
  payload, 
  process.env.JWT_SECRET,
  { expiresIn: process.env.JWT_EXPIRES_IN }
);

// Example: Moodle API call
const moodleResponse = await fetch(
  `${process.env.MOODLE_URL}/webservice/rest/server.php?wstoken=${process.env.MOODLE_TOKEN}`
);
```

### Frontend (Flutter)

Access configuration constants from `ApiConfig`:

```dart
import 'package:your_app/config/api_config.dart';

// Example: API call
final response = await http.get(
  Uri.parse('${ApiConfig.baseUrl}/courses')
);

// Example: Moodle integration
final moodleUrl = ApiConfig.moodleUrl;
```

---

## Environment-Specific Configuration

### Development
- Backend: `http://localhost:5000`
- Frontend connects to localhost

### Production
1. **Backend:**
   - Set `NODE_ENV=production`
   - Use HTTPS URL for `BASE_URL`
   - Update `CORS_ORIGIN` to specific domain
   - Use strong, random `JWT_SECRET`

2. **Frontend:**
   - Update `ApiConfig.baseUrl` to production backend URL
  - No extra keys are required for the current direct-enrollment flow

---

## Setup Instructions

### First Time Setup

1. **Backend:**
   ```bash
   cd backend
   cp .env.example .env
   # Edit .env with your actual credentials
   npm install
   npm start
   ```

2. **Frontend:**
   ```bash
   cd frontend
   flutter pub get
   # Update lib/config/api_config.dart if needed
   flutter run
   ```

### Team Collaboration

1. **Share `.env.example`** (template) via Git
2. **Never share `.env`** (contains secrets)
3. **Team members create their own `.env`** from the example
4. **For production:** Use environment variables from your hosting platform (Heroku, AWS, etc.)

---

## Troubleshooting

### Backend won't start
- Verify `.env` file exists in `/backend/` directory
- Check PORT is not already in use
- Ensure `JWT_SECRET` is set

### Frontend can't connect
- Verify `ApiConfig.baseUrl` matches backend URL
- For Android emulator, use `http://10.0.2.2:5000/api`
- For iOS simulator, use `http://localhost:5000/api`
- For physical device, use your computer's local IP (e.g., `http://192.168.1.100:5000/api`)

### Moodle integration not working
- Verify Moodle tokens have correct permissions
- Check `MOODLE_URL` has no trailing slash
- Ensure Moodle web services are enabled

### Enrollment issues
- Verify Moodle enrollment and API connectivity
- Confirm the selected course and user session are valid

---

## Additional Resources

- [Moodle Web Services Documentation](https://docs.moodle.org/dev/Web_services)
- [JWT Best Practices](https://tools.ietf.org/html/rfc8725)
