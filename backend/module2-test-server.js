/**
 * Module 2: User Module — Standalone Test Server
 * ─────────────────────────────────────────────────────────────────────────────
 * Runs on port 5001 WITHOUT needing PostgreSQL.
 * Uses in-memory mock data so you can test all User Module endpoints NOW.
 *
 * Run:  node module2-test-server.js
 * ─────────────────────────────────────────────────────────────────────────────
 */

const express = require('express');
const jwt = require('jsonwebtoken');
const bcrypt = require('bcryptjs');
const { body, validationResult } = require('express-validator');

const app = express();
const PORT = 5001;
const SECRET = 'module2-test-secret';

app.use(express.json());

// ─── In-Memory "Database" ────────────────────────────────────────────────────
const users = [
    {
        id: 'usr-admin-0001',
        name: 'Priya Jaiswal',
        email: 'admin@lms.com',
        password_hash: bcrypt.hashSync('Admin@123', 10),
        role: 'admin',
        avatar_url: null,
        created_at: '2026-03-01T06:00:00Z',
    },
    {
        id: 'usr-student-0002',
        name: 'Aarav Sharma',
        email: 'aarav@lms.com',
        password_hash: bcrypt.hashSync('Student@123', 10),
        role: 'student',
        avatar_url: null,
        created_at: '2026-03-01T07:00:00Z',
    },
    {
        id: 'usr-student-0003',
        name: 'Diya Patel',
        email: 'diya@lms.com',
        password_hash: bcrypt.hashSync('Student@123', 10),
        role: 'student',
        avatar_url: null,
        created_at: '2026-03-01T08:00:00Z',
    },
    {
        id: 'usr-student-0004',
        name: 'Rohan Mehta',
        email: 'rohan@lms.com',
        password_hash: bcrypt.hashSync('Student@123', 10),
        role: 'student',
        avatar_url: null,
        created_at: '2026-03-02T09:00:00Z',
    },
    {
        id: 'usr-student-0005',
        name: 'Ananya Gupta',
        email: 'ananya@lms.com',
        password_hash: bcrypt.hashSync('Student@123', 10),
        role: 'student',
        avatar_url: null,
        created_at: '2026-03-02T10:00:00Z',
    },
];

// Helper: strip password from user output
const safe = (u) => {
    const { password_hash, ...rest } = u;
    return rest;
};

// ─── Middleware: Authenticate ─────────────────────────────────────────────────
const authenticate = (req, res, next) => {
    const header = req.headers.authorization;
    if (!header || !header.startsWith('Bearer ')) {
        return res.status(401).json({ error: 'Access denied. No token provided.' });
    }
    try {
        const decoded = jwt.verify(header.split(' ')[1], SECRET);
        const user = users.find(u => u.id === decoded.id);
        if (!user) return res.status(401).json({ error: 'User not found.' });
        req.user = user;
        next();
    } catch (e) {
        return res.status(401).json({ error: e.name === 'TokenExpiredError' ? 'Token expired.' : 'Invalid token.' });
    }
};

// ─── Middleware: Authorize ────────────────────────────────────────────────────
const authorize = (...roles) => (req, res, next) => {
    if (!roles.includes(req.user.role)) {
        return res.status(403).json({ error: 'Access denied. Insufficient permissions.' });
    }
    next();
};

// ═══════════════════════════════════════════════════════════════════════════════
// AUTH HELPER: POST /auth/login  (to get a token for testing)
// ═══════════════════════════════════════════════════════════════════════════════
app.post('/auth/login', async (req, res) => {
    const { email, password } = req.body;
    const user = users.find(u => u.email === email);
    if (!user || !(await bcrypt.compare(password, user.password_hash))) {
        return res.status(401).json({ error: 'Invalid credentials.' });
    }
    const token = jwt.sign({ id: user.id }, SECRET, { expiresIn: '1d' });
    res.json({ message: 'Login OK', token, user: safe(user) });
});

// ═══════════════════════════════════════════════════════════════════════════════
// MODULE 2 — USER ENDPOINTS
// ═══════════════════════════════════════════════════════════════════════════════

// ── GET /api/users/me ────────────────────────────────────────────────────────
app.get('/api/users/me', authenticate, (req, res) => {
    res.json({ user: safe(req.user) });
});

// ── PUT /api/users/me ────────────────────────────────────────────────────────
app.put('/api/users/me',
    authenticate,
    body('name').optional().trim().notEmpty().withMessage('Name cannot be empty'),
    body('avatar_url').optional().isURL().withMessage('avatar_url must be a valid URL'),
    (req, res) => {
        const errors = validationResult(req);
        if (!errors.isEmpty()) return res.status(400).json({ error: 'Validation failed', details: errors.array() });

        const { name, avatar_url } = req.body;
        const idx = users.findIndex(u => u.id === req.user.id);

        if (name !== undefined) users[idx].name = name;
        if (avatar_url !== undefined) users[idx].avatar_url = avatar_url;

        res.json({ message: 'Profile updated successfully.', user: safe(users[idx]) });
    });

// ── GET /api/users  (admin, paginated + filterable) ──────────────────────────
app.get('/api/users', authenticate, authorize('admin'), (req, res) => {
    const page = Math.max(1, parseInt(req.query.page) || 1);
    const limit = Math.min(100, parseInt(req.query.limit) || 20);
    const search = (req.query.search || '').toLowerCase();
    const role = req.query.role;

    let filtered = users.filter(u => {
        const matchSearch = !search ||
            u.name.toLowerCase().includes(search) ||
            u.email.toLowerCase().includes(search);
        const matchRole = !role || u.role === role;
        return matchSearch && matchRole;
    });

    const total = filtered.length;
    const paged = filtered.slice((page - 1) * limit, page * limit);

    res.json({
        users: paged.map(safe),
        pagination: { total, page, limit, totalPages: Math.ceil(total / limit) },
    });
});

// ── GET /api/users/:id  (admin) ───────────────────────────────────────────────
app.get('/api/users/:id', authenticate, authorize('admin'), (req, res) => {
    const user = users.find(u => u.id === req.params.id);
    if (!user) return res.status(404).json({ error: 'User not found.' });
    res.json({ user: safe(user) });
});

// ── DELETE /api/users/:id  (admin) ───────────────────────────────────────────
app.delete('/api/users/:id', authenticate, authorize('admin'), (req, res) => {
    if (req.params.id === req.user.id) {
        return res.status(400).json({ error: 'You cannot delete your own admin account.' });
    }
    const idx = users.findIndex(u => u.id === req.params.id);
    if (idx === -1) return res.status(404).json({ error: 'User not found.' });
    const deleted = users.splice(idx, 1)[0];
    res.json({ message: `User "${deleted.name}" deleted successfully.` });
});

// ─── Health check ─────────────────────────────────────────────────────────────
app.get('/health', (req, res) => {
    res.json({ status: 'OK', module: 'User Module (Module 2)', timestamp: new Date().toISOString() });
});

// ─── Start ────────────────────────────────────────────────────────────────────
app.listen(PORT, () => {
    console.log('');
    console.log('╔══════════════════════════════════════════════════════╗');
    console.log('║      LMS Backend — Module 2: User Module             ║');
    console.log('╠══════════════════════════════════════════════════════╣');
    console.log(`║  Server running on  http://localhost:${PORT}         ║`);
    console.log('╠══════════════════════════════════════════════════════╣');
    console.log('║  TEST ACCOUNTS                                       ║');
    console.log('║  Admin   → admin@lms.com   / Admin@123               ║');
    console.log('║  Student → aarav@lms.com   / Student@123             ║');
    console.log('╠══════════════════════════════════════════════════════╣');
    console.log('║  ENDPOINTS (Module 2)                                ║');
    console.log('║  POST   /auth/login                (get token)       ║');
    console.log('║  GET    /api/users/me              (any)             ║');
    console.log('║  PUT    /api/users/me              (any)             ║');
    console.log('║  GET    /api/users                 (admin only)      ║');
    console.log('║  GET    /api/users/:id             (admin only)      ║');
    console.log('║  DELETE /api/users/:id             (admin only)      ║');
    console.log('╚══════════════════════════════════════════════════════╝');
    console.log('');
});
