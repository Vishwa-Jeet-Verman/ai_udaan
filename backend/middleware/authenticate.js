const jwt = require('jsonwebtoken');

const buildUserFromToken = (decoded) => {
    if (!decoded) return null;

    return {
        id: decoded.id,
        name: decoded.name || '',
        username: decoded.username || null,
        email: decoded.email || null,
        role: decoded.role || 'student',
        moodle_id: decoded.moodle_id || decoded.moodleId || null,
        avatar_url: decoded.avatar_url || null,
        moodle_token: decoded.moodle_token || null,
    };
};

const authenticate = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;

        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({ error: 'Access denied. No token provided.' });
        }

        const token = authHeader.split(' ')[1];
        const decoded = jwt.verify(token, process.env.JWT_SECRET);

        const user = buildUserFromToken(decoded);

        if (!user) {
            return res.status(401).json({ error: 'Invalid token.' });
        }

        req.user = user;
        next();
    } catch (error) {
        if (error.name === 'JsonWebTokenError') {
            return res.status(401).json({ error: 'Invalid token.' });
        }
        if (error.name === 'TokenExpiredError') {
            return res.status(401).json({ error: 'Token expired.' });
        }
        next(error);
    }
};

// Optional auth — attaches user if token present, continues either way
const optionalAuth = async (req, res, next) => {
    try {
        const authHeader = req.headers.authorization;
        if (authHeader && authHeader.startsWith('Bearer ')) {
            const token = authHeader.split(' ')[1];
            const decoded = jwt.verify(token, process.env.JWT_SECRET);
            const user = buildUserFromToken(decoded);
            if (user) req.user = user;
        }
    } catch (_) {
        // Ignore token errors for optional auth
    }
    next();
};

module.exports = { authenticate, optionalAuth };
