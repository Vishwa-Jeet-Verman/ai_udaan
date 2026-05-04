const rateLimit = require('express-rate-limit');

// Global rate limiter (but SKIP message routes - they have their own limiter)
const globalLimiter = rateLimit({
    windowMs: 15 * 60 * 1000, // 15 minutes
    max: 100,
    message: { error: 'Too many requests, please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req) => {
        // 🔥 EXCLUDE message routes from global limiter - they use messageLimiter instead
        return req.path.startsWith('/api/messages');
    }
});

// Stricter limiter for auth routes
const authLimiter = rateLimit({
    windowMs: 15 * 60 * 1000,
    max: 20,
    message: { error: 'Too many authentication attempts, please try again later.' },
    standardHeaders: true,
    legacyHeaders: false,
});

// Relaxed limiter for message polling (frontend polls every 10s = 6 req/min per user)
const messageLimiter = rateLimit({
    windowMs: 1 * 60 * 1000, // 1 minute window
    max: 120, // 120 requests per minute = 2 per second (allows polling from multiple users)
    message: { error: 'Message polling rate limit exceeded. Please try again in a moment.' },
    standardHeaders: true,
    legacyHeaders: false,
    skip: (req, res) => {
        // 🔥 Allow unlimited GET requests for messages (only limit POST/writes)
        return req.method === 'GET';
    }
});

module.exports = { globalLimiter, authLimiter, messageLimiter };
