const jwt = require('jsonwebtoken');
const moodleLoginService = require('../services/moodle.login.service');
const moodleService = require('../services/moodle.service');

/**
 * Moodle login endpoint
 * Authenticates user with Moodle and returns JWT with Moodle token
 */
exports.moodleLogin = async (req, res, next) => {
    try {
        const { username, password } = req.body;

        if (!username || !password) {
            return res.status(400).json({ 
                error: 'Username and password are required' 
            });
        }

        console.log(`[Auth] 🔐 Moodle login attempt for: ${username}`);

        // Authenticate with Moodle and get token
        const moodleUser = await moodleLoginService.authenticateUser(username, password);

        console.log(`[Auth] ✅ Moodle authentication successful for user ${moodleUser.userid}`);

        // Build JWT with Moodle token
        const payload = {
            id: `moodle-${moodleUser.userid}`, // App user ID
            moodle_id: moodleUser.userid,       // Moodle numeric ID
            moodle_token: moodleUser.token,     // User's personal Moodle token
            username: moodleUser.username,
            name: moodleUser.fullname,
            email: moodleUser.email,
            role: moodleUser.userid === 2 ? 'admin' : 'student', // Adjust as needed
            iat: Math.floor(Date.now() / 1000),
        };

        const token = jwt.sign(payload, process.env.JWT_SECRET, {
            expiresIn: '7d',
        });

        console.log(`[Auth] 📝 JWT issued for user ${moodleUser.userid}`);

        res.status(200).json({
            message: 'Login successful',
            token: token,
            user: {
                id: payload.id,
                moodle_id: moodleUser.userid,
                username: moodleUser.username,
                name: moodleUser.fullname,
                email: moodleUser.email,
                role: payload.role,
            }
        });
    } catch (err) {
        console.error(`[Auth] ❌ Moodle login failed:`, err.message);
        res.status(401).json({ 
            error: 'Authentication failed',
            message: err.message 
        });
    }
};

/**
 * Verify that current user's Moodle token is still valid
 */
exports.verifyMoodleToken = async (req, res, next) => {
    try {
        if (!req.user) {
            return res.status(401).json({ error: 'Not authenticated' });
        }

        const moodleToken = req.user.moodle_token;
        if (!moodleToken) {
            return res.status(401).json({ error: 'No Moodle token in JWT' });
        }

        console.log(`[Auth] 🔍 Verifying Moodle token for user ${req.user.moodle_id}...`);

        const isValid = await moodleLoginService.verifyToken(moodleToken);

        if (isValid) {
            return res.json({ 
                valid: true,
                message: 'Token is valid',
                user: {
                    id: req.user.id,
                    moodle_id: req.user.moodle_id,
                    name: req.user.name,
                }
            });
        } else {
            return res.status(401).json({ 
                valid: false,
                error: 'Moodle token is invalid or expired'
            });
        }
    } catch (err) {
        console.error(`[Auth] ❌ Token verification failed:`, err.message);
        res.status(500).json({
            error: 'Token verification failed',
            message: err.message
        });
    }
};
