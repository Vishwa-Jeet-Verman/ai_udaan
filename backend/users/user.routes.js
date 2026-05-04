const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authenticate');
const authorize = require('../middleware/authorize');
const {
    getProfile,
    updateProfile,
    updateProfileValidation,
    listUsers,
    getUserById,
    deleteUser,
    uploadAvatar,
    deleteAvatar,
    avatarUpload,
} = require('./user.controller');

// Authenticated user — own profile
router.get('/me', authenticate, getProfile);
router.put('/me', authenticate, updateProfileValidation, updateProfile);

// Avatar upload — wrap multer to catch its errors inline
router.post('/avatar', authenticate, (req, res, next) => {
    avatarUpload(req, res, (err) => {
        if (err) {
            console.error('[Avatar Route] Multer error:', err.code, err.message);
            if (err.code === 'LIMIT_FILE_SIZE') {
                return res.status(400).json({ error: 'Image too large. Maximum size is 5MB.' });
            }
            if (err.code === 'LIMIT_UNEXPECTED_FILE') {
                return res.status(400).json({ error: 'Unexpected file field. Use field name "avatar".' });
            }
            return res.status(400).json({ error: err.message || 'File upload error.' });
        }
        next();
    });
}, uploadAvatar);

router.delete('/avatar', authenticate, deleteAvatar);

// Admin — user management
router.get('/', authenticate, authorize('admin'), listUsers);
router.get('/:id', authenticate, authorize('admin'), getUserById);
router.delete('/:id', authenticate, authorize('admin'), deleteUser);

module.exports = router;
