require('dotenv').config();

const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const path = require('path');
const http = require('http');
const { Server } = require('socket.io');
const jwt = require('jsonwebtoken');

const { globalLimiter, messageLimiter } = require('./middleware/rateLimiter');
const errorHandler = require('./middleware/errorHandler');

// ─── Import routes ───────────────────────────────────────────────────────────
const authRoutes = require('./auth/auth.routes');
const userRoutes = require('./users/user.routes');
const courseRoutes = require('./courses/course.routes');
const lessonRoutes = require('./lessons/lesson.routes');
const purchaseRoutes = require('./purchases/purchase.routes');
const messageRoutes = require('./messages/message.routes');
const downloadRoutes = require('./downloads/download.routes');
const gradeRoutes = require('./grades/grade.routes');
const notificationRoutes = require('./notifications/notification.routes');
const calendarRoutes = require('./calendar/calendar.routes');
const supportRoutes = require('./support/support.routes');
const paymentRoutes = require('./payments/payment.routes');

const app = express();
const httpServer = http.createServer(app);

// Trust reverse proxy (required for express-rate-limit behind Hostinger/nginx)
app.set('trust proxy', 1);

// ─── Global middleware ────────────────────────────────────────────────────────
app.use(helmet({
    crossOriginResourcePolicy: { policy: 'cross-origin' }, // allow Flutter to load uploads
}));
app.use(cors({
    origin: process.env.CORS_ORIGIN && process.env.CORS_ORIGIN !== '*'
        ? process.env.CORS_ORIGIN.split(',').map(o => o.trim())
        : '*',
}));
app.use(morgan(process.env.NODE_ENV === 'production' ? 'combined' : 'dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));
app.use(globalLimiter);

// ─── Serve uploaded files statically ────────────────────────────────────────
// Flutter can stream videos/PDFs directly from:  http://<host>:5000/uploads/<filename>
app.use('/uploads', express.static(path.join(__dirname, 'uploads')));
app.use('/api/uploads', express.static(path.join(__dirname, 'uploads')));

// ─── Moodle image proxy ───────────────────────────────────────────────────────
// Proxies Moodle pluginfile images through the backend so Flutter clients
// don't need direct access to moodle.nighwantech.com
app.get('/api/proxy/image', async (req, res) => {
    const { url } = req.query;
    if (!url || !url.startsWith(process.env.MOODLE_URL)) {
        return res.status(400).json({ error: 'Invalid image URL' });
    }
    try {
        const axios = require('axios');
        const response = await axios.get(url, {
            responseType: 'arraybuffer',
            timeout: 10000,
            maxRedirects: 5,
        });
        const contentType = response.headers['content-type'] || 'image/jpeg';
        res.set('Content-Type', contentType);
        res.set('Cache-Control', 'public, max-age=86400');
        res.send(response.data);
    } catch (err) {
        res.status(502).json({ error: 'Failed to fetch image' });
    }
});

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/api/health', (req, res) => {
    res.json({
        status: 'OK',
        database: 'Moodle API only (no local DB)',
        storage: 'Local disk (/uploads)',
        timestamp: new Date().toISOString(),
    });
});

// ─── API routes ───────────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/courses', courseRoutes);
app.use('/api', lessonRoutes);
app.use('/api', purchaseRoutes);
app.use('/api/messages', messageLimiter, messageRoutes);
app.use('/api', downloadRoutes);
app.use('/api', gradeRoutes);
app.use('/api/notifications', notificationRoutes);
app.use('/api/calendar/events', calendarRoutes);
app.use('/api/support', supportRoutes);
app.use('/api/payments', paymentRoutes);

// ─── Socket.io setup ─────────────────────────────────────────────────────────
const io = new Server(httpServer, {
    // ✅ CORS Configuration: Allow Flutter and web clients
    cors: {
        origin: process.env.CORS_ORIGIN && process.env.CORS_ORIGIN !== '*'
            ? process.env.CORS_ORIGIN.split(',').map(o => o.trim())
            : ['http://localhost:3000', 'http://localhost:8080', 'http://localhost:3001'],
        methods: ['GET', 'POST'],
        credentials: true,
        allowEIO3: true,  // Support Socket.IO v2/3 clients (older Flutter packages)
    },
    // ✅ Transport Configuration: Use websocket only (more stable than polling)
    transports: ['websocket'],
    // ✅ Reconnection Settings: Limit reconnect loops
    reconnection: true,
    reconnectionDelay: 1000,           // Start with 1s delay
    reconnectionDelayMax: 5000,        // Max 5s delay between attempts
    reconnectionAttempts: 5,           // Max 5 reconnection attempts
    // ✅ Connection Settings
    connectTimeout: 10000,              // 10s connection timeout
    pingInterval: 25000,                // Send ping every 25s
    pingTimeout: 20000,                 // Await pong for 20s
    // ✅ Path
    path: '/socket.io',
});

// ✅ Authenticate socket connections via JWT
io.use((socket, next) => {
    try {
        const token = socket.handshake.auth?.token || socket.handshake.query?.token;
        
        if (!token) {
            console.warn('[Socket] ❌ Connection attempt without token');
            return next(new Error('Authentication required'));
        }

        const decoded = jwt.verify(token, process.env.JWT_SECRET);
        socket.user = decoded;
        socket.userId = decoded.id;
        
        console.log(`[Socket] 🔐 User ${socket.userId} authenticated`);
        next();
    } catch (err) {
        console.error(`[Socket] ❌ Authentication error:`, err.message);
        next(new Error('Invalid token'));
    }
});

io.on('connection', (socket) => {
    const userId = socket.user.id;
    const socketId = socket.id;
    
    console.log(`[Socket] ✅ User ${userId} connected (socket: ${socketId})`);
    
    // Join user-specific room for direct messages
    socket.join(`user:${userId}`);
    console.log(`[Socket] 📍 Joined room: user:${userId}`);

    socket.on('join_group', (groupId) => {
        console.log(`[Socket] User ${userId} joining group ${groupId}`);
        socket.join(`group:${groupId}`);
    });

    socket.on('leave_group', (groupId) => {
        console.log(`[Socket] User ${userId} leaving group ${groupId}`);
        socket.leave(`group:${groupId}`);
    });

    socket.on('disconnect', (reason) => {
        console.log(`[Socket] User ${userId} disconnected (reason: ${reason})`);
    });

    socket.on('error', (err) => {
        console.error(`[Socket] Error for user ${userId}:`, err);
    });
});

// ✅ Log connection events for debugging
io.on('error', (err) => {
    console.error('[Socket] Server error:', err);
});

io.on('connect_error', (err) => {
    console.error('[Socket] Connect error:', err);
});

// Make io accessible in controllers
app.set('io', io);

// ─── 404 ─────────────────────────────────────────────────────────────────────
app.use((req, res) => {
    res.status(404).json({ error: 'Route not found.' });
});

// ─── Global error handler ────────────────────────────────────────────────────
app.use(errorHandler);

// ─── Start server ─────────────────────────────────────────────────────────────
const PORT = process.env.PORT || 5000;

const startServer = async () => {
    try {
        const moodleService = require('./services/moodle.service');

        // ── Test Moodle connection ──────────────────────────────
        console.log('');
        console.log('🧪 Testing Moodle connection...');
        const moodleConnected = await moodleService.testConnection();
        if (!moodleConnected) {
            console.log('⚠️  Moodle connection failed. Some API routes may not work.');
            console.log('   Check MOODLE_URL and MOODLE_TOKEN in .env');
        }
        console.log('');

        httpServer.listen(PORT, '0.0.0.0', () => {
            console.log('');
            console.log('╔══════════════════════════════════════════════════╗');
            console.log('║        LMS Backend — Moodle-Only Runtime         ║');
            console.log('╠══════════════════════════════════════════════════╣');
            console.log(`║  API   →  http://localhost:${PORT}/api           ║`);
            console.log(`║  Files →  http://localhost:${PORT}/uploads/      ║`);
            console.log('║  DB    →  disabled                               ║');
            console.log('╚══════════════════════════════════════════════════╝');
            console.log('');
        });
    } catch (error) {
        console.error('❌ Failed to start server:', error.message);
        process.exit(1);
    }
};

startServer();

module.exports = { app, httpServer };
