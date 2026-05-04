const express = require('express');
const router = express.Router();
const { authLimiter } = require('../middleware/rateLimiter');
const { authenticate } = require('../middleware/authenticate');
const {
    register,
    checkEmailStatus,
    verifyOtp,
    login,
    forgotPassword,
    resetPassword,
    changePassword,
    checkEmailValidation,
    registerValidation,
    verifyOtpValidation,
    loginValidation,
    forgotPasswordValidation,
    resetPasswordValidation,
    changePasswordValidation,
} = require('./auth.controller');
const {
    moodleLogin,
    verifyMoodleToken,
} = require('./moodle-auth.controller');

router.post('/check-email', authLimiter, checkEmailValidation, checkEmailStatus);
router.post('/register', authLimiter, registerValidation, register);
router.post('/verify-otp', authLimiter, verifyOtpValidation, verifyOtp);
router.post('/login', authLimiter, loginValidation, login);
router.post('/forgot-password', authLimiter, forgotPasswordValidation, forgotPassword);
router.post('/reset-password', authLimiter, resetPasswordValidation, resetPassword);
router.post('/change-password', authenticate, changePasswordValidation, changePassword);

// Moodle authentication routes
router.post('/moodle-login', authLimiter, moodleLogin);
router.get('/verify-moodle-token', authenticate, verifyMoodleToken);

module.exports = router;
