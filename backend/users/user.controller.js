const { body, validationResult } = require('express-validator');
const multer = require('multer');
const path = require('path');
const fs = require('fs');
const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const moodleService = require('../services/moodle.service');
const { sendProfileUpdatedEmail } = require('../services/email.service');

// ── Avatar upload — local disk storage ───────────────────────────────────────
const AVATAR_DIR = path.join(__dirname, '../uploads/avatars');
if (!fs.existsSync(AVATAR_DIR)) fs.mkdirSync(AVATAR_DIR, { recursive: true });

const avatarStorage = multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, AVATAR_DIR),
    filename: (_req, file, cb) => {
        const ext = path.extname(file.originalname).toLowerCase() || '.jpg';
        cb(null, `${Date.now()}-${crypto.randomBytes(6).toString('hex')}${ext}`);
    },
});

const upload = multer({
    storage: avatarStorage,
    limits: { fileSize: 5 * 1024 * 1024 }, // 5 MB
    // No fileFilter — accept any file; Flutter always sends image/jpeg
});

const formatUserResponse = (user) => {
    if (!user) return null;

    return {
        id: user.id,
        name: user.name,
        username: user.username || null,
        email: user.email || null,
        role: user.role || 'student',
        avatar_url: user.avatar_url || null,
        moodleId: user.moodle_id || null,
        createdAt: user.createdAt || null,
        updatedAt: user.updatedAt || null,
    };
};

const resolveRuntimeProfile = async (authUser) => {
    const baseProfile = {
        id: authUser.id,
        name: authUser.name || authUser.username || 'Moodle User',
        username: authUser.username || null,
        email: authUser.email || null,
        role: authUser.role || 'student',
        avatar_url: authUser.avatar_url || null,
        moodle_id: authUser.moodle_id || authUser.moodleId || null,
    };

    const moodleUser = await moodleService.resolveMoodleUserForLocalUser(baseProfile);
    if (!moodleUser) {
        return baseProfile;
    }

    return {
        ...baseProfile,
        name: moodleUser.fullname || baseProfile.name,
        username: moodleUser.username || baseProfile.username,
        email: moodleUser.email || baseProfile.email,
        // Always prefer the avatar already in the JWT (set by uploadAvatar).
        // Only fall back to Moodle's profileimageurl if we have nothing locally.
        avatar_url: baseProfile.avatar_url || moodleUser.profileimageurl || null,
        moodle_id: moodleUser.id || baseProfile.moodle_id,
    };
};

const getProfile = async (req, res, next) => {
    try {
        const profile = await resolveRuntimeProfile(req.user);
        return res.json({ user: formatUserResponse(profile) });
    } catch (error) {
        next(error);
    }
};

const updateProfileValidation = [
    body('name')
        .optional()
        .trim()
        .notEmpty()
        .withMessage('Name cannot be empty')
        .matches(/^[A-Za-z\s]+$/)
        .withMessage('Name can contain only letters and spaces')
        .custom((value) => {
            const lettersOnly = value.replace(/\s+/g, '');
            if (lettersOnly.length < 3) {
                throw new Error('Name must be at least 3 characters long');
            }
            return true;
        }),
    body('avatar_url')
        .optional()
        .isURL()
        .withMessage('avatar_url must be a valid URL'),
];

const updateProfile = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error: errors.array()[0].msg, details: errors.array() });
        }

        const { name } = req.body;
        if (!name) {
            return res.status(400).json({ error: 'No fields provided to update.' });
        }

        const profile = await resolveRuntimeProfile(req.user);
        const moodleId = profile.moodle_id;
        if (!moodleId) {
            return res.status(400).json({ error: 'Moodle account not linked. Cannot update profile.' });
        }

        // Split full name into Moodle firstname / lastname
        const trimmedName = name.trim().replace(/\s+/g, ' ');
        const spaceIndex = trimmedName.indexOf(' ');
        const firstname = spaceIndex !== -1 ? trimmedName.slice(0, spaceIndex) : trimmedName;
        const lastname = spaceIndex !== -1 ? trimmedName.slice(spaceIndex + 1) : '';

        await moodleService.updateUserProfile(moodleId, { firstname, lastname });

        // Notify user by email (non-blocking)
        if (profile.email) {
            sendProfileUpdatedEmail(profile.email, profile.name || trimmedName, trimmedName)
                .catch((err) => console.error('Profile update email failed:', err.message));
        }

        return res.json({ success: true, name: trimmedName });
    } catch (error) {
        next(error);
    }
};

const uploadAvatar = async (req, res, next) => {
    try {
        console.log('[Avatar] Upload request received');
        console.log('[Avatar] req.file:', req.file ? req.file.filename : 'MISSING');
        console.log('[Avatar] req.user:', req.user ? JSON.stringify({ id: req.user.id, role: req.user.role }) : 'MISSING');

        if (!req.file) {
            return res.status(400).json({ error: 'No image file provided.' });
        }

        if (!req.user || !req.user.id) {
            return res.status(401).json({ error: 'Authentication required.' });
        }

        const jwtSecret = process.env.JWT_SECRET;
        if (!jwtSecret) {
            console.error('[Avatar] JWT_SECRET is not set in environment!');
            return res.status(500).json({ error: 'Server configuration error.' });
        }

        const baseUrl = process.env.BASE_URL || `${req.protocol}://${req.get('host')}`;
        const avatarPath = `/uploads/avatars/${req.file.filename}`;
        const avatarUrl = `${baseUrl}${avatarPath}`;
        console.log('[Avatar] Generated avatar URL:', avatarUrl);

        // Delete old avatar file if it was previously stored locally
        const oldAvatarUrl = req.user?.avatar_url || '';
        if (oldAvatarUrl.includes('/uploads/avatars/')) {
            const oldFilename = path.basename(oldAvatarUrl.split('?')[0]);
            const oldPath = path.join(AVATAR_DIR, oldFilename);
            if (fs.existsSync(oldPath)) {
                fs.unlink(oldPath, (err) => {
                    if (err) console.error('[Avatar] Could not delete old avatar:', err.message);
                });
            }
        }

        // Sync profile picture to Moodle (non-blocking — failure won't break the response)
        const moodleId = req.user.moodle_id;
        const moodleToken = req.user.moodle_token;
        console.log('[Avatar] moodle_id:', moodleId, '| has moodle_token:', !!moodleToken);
        if (moodleId) {
            moodleService.uploadUserProfilePicture(
                moodleId,
                moodleToken || null,
                req.file.path,
                req.file.filename,
            ).then((ok) => {
                if (ok) console.log('[Avatar] ✅ Moodle profile picture synced');
                else console.warn('[Avatar] ⚠️  Moodle sync failed (local upload still OK)');
            }).catch((err) => {
                console.error('[Avatar] Moodle sync error (non-fatal):', err.message);
            });
        } else {
            console.warn('[Avatar] No moodle_id — skipping Moodle sync');
        }

        // Issue a new JWT with the updated avatar_url so it persists across sessions
        const newPayload = {
            id: req.user.id,
            moodle_id: req.user.moodle_id,
            moodleId: req.user.moodle_id,
            name: req.user.name,
            username: req.user.username,
            email: req.user.email,
            role: req.user.role,
            avatar_url: avatarPath,   // store relative path — client prepends its own baseUrl
            moodle_token: req.user.moodle_token,
        };
        const newToken = jwt.sign(newPayload, jwtSecret, {
            expiresIn: process.env.JWT_EXPIRES_IN || '7d',
        });

        const updatedUser = { ...req.user, avatar_url: avatarPath };
        console.log('[Avatar] Upload successful, returning new token');

        return res.json({
            token: newToken,
            user: formatUserResponse(updatedUser),
        });
    } catch (error) {
        console.error('[Avatar] Upload error:', error.message);
        console.error('[Avatar] Stack:', error.stack);
        next(error);
    }
};

const deleteAvatar = async (_req, res) => {
    return res.status(400).json({
        error: 'Avatar changes are managed in Moodle. Please update your profile picture in Moodle.',
    });
};

const listUsers = async (_req, res) => {
    return res.status(400).json({
        error: 'User listing is unavailable because local database storage has been removed.',
    });
};

const getUserById = async (_req, res) => {
    return res.status(400).json({
        error: 'User detail view is unavailable because local database storage has been removed.',
    });
};

const deleteUser = async (_req, res) => {
    return res.status(400).json({
        error: 'User deletion is unavailable because local database storage has been removed.',
    });
};

module.exports = {
    getProfile,
    updateProfile,
    updateProfileValidation,
    listUsers,
    getUserById,
    deleteUser,
    uploadAvatar,
    deleteAvatar,
    avatarUpload: upload.single('avatar'),
};
