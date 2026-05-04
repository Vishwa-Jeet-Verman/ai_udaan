# AI UDAAN - Learning Management System

A comprehensive Learning Management System (LMS) built with Flutter (frontend) and Node.js/Express (backend), integrated with Moodle and Razorpay payment gateway.

## 🚀 Features

### Core Features
- 📚 **Course Management** - Browse, enroll, and manage courses
- 🎓 **Moodle Integration** - Seamless integration with Moodle LMS
- 💳 **Payment Integration** - Razorpay payment gateway for paid courses
- 👤 **User Authentication** - Secure JWT-based authentication
- 📱 **Multi-platform** - Android, iOS, and Web support
- 🌐 **Multi-language** - English and Hindi support
- 🎨 **Dark Mode** - Light and dark theme support
- 📧 **Email Notifications** - Enrollment confirmations and updates
- 🔔 **Push Notifications** - Real-time notifications via Socket.IO
- 📊 **Progress Tracking** - Track course progress and grades
- 💬 **Messaging** - Group and private messaging
- 📅 **Calendar** - Event management and scheduling

### Payment Features
- ✅ Free course enrollment
- ✅ Paid course enrollment with Razorpay
- ✅ Secure payment verification
- ✅ Automatic enrollment after payment
- ✅ Email and push notifications

## 🏗️ Architecture

```
AI_UDAAN/
├── backend/              # Node.js/Express API
│   ├── auth/            # Authentication
│   ├── courses/         # Course management
│   ├── payments/        # Razorpay integration
│   ├── users/           # User management
│   ├── messages/        # Messaging system
│   ├── notifications/   # Notification system
│   └── services/        # Moodle integration
│
├── frontend/            # Flutter application
│   ├── lib/
│   │   ├── models/      # Data models
│   │   ├── providers/   # State management
│   │   ├── screens/     # UI screens
│   │   ├── services/    # API services
│   │   └── widgets/     # Reusable widgets
│   └── assets/          # Images and assets
│
└── docs/                # Documentation
```

## 📋 Prerequisites

### Backend
- Node.js 16+ and npm
- Moodle instance with API access
- Razorpay account (for payments)
- SMTP server (for emails)

### Frontend
- Flutter 3.11+
- Dart 3.11+
- Android Studio / Xcode (for mobile development)

## 🛠️ Installation

### 1. Clone Repository
```bash
git clone https://github.com/Vishwa-Jeet-Verma/ai_udaan.git
cd ai_udaan
```

### 2. Backend Setup

```bash
cd backend

# Install dependencies
npm install

# Create environment file
cp .env.example .env

# Edit .env with your credentials
nano .env
```

**Required Environment Variables:**
```env
# Server
PORT=9000
NODE_ENV=development

# JWT
JWT_SECRET=your-secret-key

# Moodle
MOODLE_URL=https://your-moodle-instance.com
MOODLE_TOKEN=your-moodle-token

# Razorpay
RAZORPAY_KEY_ID=rzp_test_xxx
RAZORPAY_KEY_SECRET=your-secret

# Email
SMTP_HOST=smtp.example.com
SMTP_USER=your-email@example.com
SMTP_PASS=your-password
```

### 3. Frontend Setup

```bash
cd frontend

# Install dependencies
flutter pub get

# Create environment file
cp .env.example .env

# Edit .env with your configuration
nano .env
```

**Required Environment Variables:**
```env
APP_ENV=dev
API_BASE_URL_LOCAL=http://localhost:9000/api
NEXT_PUBLIC_RAZORPAY_KEY_ID=rzp_test_xxx
MOODLE_URL=https://your-moodle-instance.com
```

## 🚀 Running the Application

### Development Mode

**Terminal 1 - Backend:**
```bash
cd backend
npm run dev
```

**Terminal 2 - Frontend:**
```bash
cd frontend
flutter run
```

### Using Helper Scripts

```bash
# Start backend
./dev-backend.sh

# Start frontend
./dev-frontend.sh

# Start both (requires tmux)
./dev-up.sh
```

## 📱 Building for Production

### Android
```bash
cd frontend
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

### iOS
```bash
cd frontend
flutter build ipa --release
# Output: build/ios/ipa/
```

### Web
```bash
cd frontend
flutter build web --release
# Output: build/web/
```

## 🧪 Testing

### Backend Tests
```bash
cd backend
npm test
```

### Frontend Tests
```bash
cd frontend
flutter test
```

### Payment Testing

Use Razorpay test cards:
- **Success**: 4111 1111 1111 1111
- **Failure**: 4111 1111 1111 1112
- CVV: Any 3 digits
- Expiry: Any future date

## 📚 Documentation

- [Payment Integration Guide](PAYMENT_INTEGRATION.md)
- [Quick Payment Test](QUICK_PAYMENT_TEST.md)
- [Payment Flow Diagram](PAYMENT_FLOW_DIAGRAM.md)
- [Production Deployment Checklist](PRODUCTION_DEPLOYMENT_CHECKLIST.md)
- [Issues Fixed](ISSUES_FIXED.md)
- [.gitignore Guide](.gitignore_GUIDE.md)

## 🔒 Security

- ✅ JWT-based authentication
- ✅ Password hashing with bcrypt
- ✅ HTTPS in production
- ✅ CORS configuration
- ✅ Rate limiting
- ✅ Input validation
- ✅ SQL injection prevention
- ✅ XSS protection
- ✅ Payment signature verification

**Important**: Never commit `.env` files or expose API keys!

## 🌐 API Endpoints

### Authentication
- `POST /api/auth/register` - Register new user
- `POST /api/auth/login` - Login user
- `POST /api/auth/verify-otp` - Verify OTP

### Courses
- `GET /api/courses` - List all courses
- `GET /api/courses/:id` - Get course details
- `GET /api/courses/my` - Get enrolled courses

### Payments
- `POST /api/payments/courses/:id/order` - Create payment order
- `POST /api/payments/courses/:id/verify` - Verify payment

### Enrollments
- `POST /api/courses/:id/enroll` - Enroll in course
- `GET /api/enrollments` - Get user enrollments

See [API_DOCS.md](backend/API_DOCS.md) for complete API documentation.

## 🎨 Screenshots

<!-- Add screenshots here -->

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📝 License

This project is proprietary and confidential.

## 👥 Team

- **Developer**: Vishwa Jeet Verma
- **Organization**: NGTech

## 📞 Support

For support, email: info@aiudaanbootcamp.com

## 🙏 Acknowledgments

- [Flutter](https://flutter.dev/)
- [Node.js](https://nodejs.org/)
- [Moodle](https://moodle.org/)
- [Razorpay](https://razorpay.com/)
- [Socket.IO](https://socket.io/)

## 📈 Roadmap

- [ ] Add video conferencing
- [ ] Implement AI-powered recommendations
- [ ] Add gamification features
- [ ] Implement offline mode
- [ ] Add analytics dashboard
- [ ] Multi-tenant support
- [ ] Advanced reporting

## 🐛 Known Issues

See [Issues](https://github.com/Vishwa-Jeet-Verma/ai_udaan/issues) for a list of known issues.

## 📊 Project Status

🟢 **Active Development**

---

Made with ❤️ by NGTech
