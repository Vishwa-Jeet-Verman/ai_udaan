const crypto = require('crypto');
const jwt = require('jsonwebtoken');
const { validationResult, body } = require('express-validator');
const moodleService = require('../services/moodle.service');
const { sendOtpEmail, sendWelcomeEmail, sendPasswordResetEmail, sendPasswordChangedEmail, sendForgotPasswordOtpEmail } = require('../services/email.service');
const { validatePassword } = require('../utils/passwordValidator');

// ─── In-memory OTP store ──────────────────────────────────────────────────────
// Structure: email → { otp, expiresAt, name, username, password, attempts }
// pendingRegistrations: email → { name, username, email, password, otp, expiresAt, attempts }
const pendingRegistrations = new Map();

// pendingPasswordResets: email → { otp, expiresAt, attempts, moodleUserId, username, name }
const pendingPasswordResets = new Map();

const OTP_TTL_MS = 10 * 60 * 1000; // 10 minutes
const OTP_MAX_ATTEMPTS = 5;

const generateOtp = () => crypto.randomInt(100000, 999999).toString();

const cleanExpiredOtps = () => {
    const now = Date.now();
    for (const [email, data] of pendingRegistrations) {
        if (data.expiresAt < now) {
            pendingRegistrations.delete(email);
        }
    }
};

// ─── OTP validation rules ─────────────────────────────────────────────────────
const verifyOtpValidation = [
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('otp')
        .trim()
        .isLength({ min: 6, max: 6 })
        .isNumeric()
        .withMessage('OTP must be a 6-digit number'),
];

const checkEmailValidation = [
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('purpose')
        .optional()
        .isIn(['register', 'reset-password'])
        .withMessage('Invalid email check purpose'),
];

const NAME_PATTERN = /^[A-Za-z\s]+$/;
const USERNAME_PATTERN = /^[a-z0-9._-]+$/;

const normalizeRegistrationUsername = (username) =>
    String(username || '')
        .trim()
        .toLowerCase();

const validateRegistrationName = (name) => {
    const normalizedName = String(name || '')
        .trim()
        .replace(/\s+/g, ' ');

    if (!normalizedName) {
        return 'Name is required';
    }

    if (!NAME_PATTERN.test(normalizedName)) {
        return 'Name can contain only letters and spaces';
    }

    if (normalizedName.replace(/\s+/g, '').length < 3) {
        return 'Name must be at least 3 characters long';
    }

    return null;
};

const validateRegistrationUsername = (username) => {
    const normalizedUsername = normalizeRegistrationUsername(username);

    if (!normalizedUsername) {
        return 'Username is required';
    }

    if (!USERNAME_PATTERN.test(normalizedUsername)) {
        return 'Username can contain only letters, numbers, dots, underscores, and hyphens';
    }

    if (normalizedUsername.length < 3) {
        return 'Username must be at least 3 characters long';
    }

    if (normalizedUsername.length > 40) {
        return 'Username must be at most 40 characters long';
    }

    if (/^[._-]|[._-]$/.test(normalizedUsername)) {
        return 'Username cannot start or end with a dot, underscore, or hyphen';
    }

    return null;
};

const findPendingRegistrationByUsername = (username, ignoredEmail = null) => {
    const normalizedUsername = normalizeRegistrationUsername(username);
    if (!normalizedUsername) {
        return null;
    }

    for (const [email, data] of pendingRegistrations) {
        if (ignoredEmail && email === ignoredEmail) {
            continue;
        }

        if (normalizeRegistrationUsername(data?.username) === normalizedUsername) {
            return data;
        }
    }

    return null;
};

const registerValidation = [
    body('name').custom((name) => {
        const errorMessage = validateRegistrationName(name);
        if (errorMessage) {
            throw new Error(errorMessage);
        }

        return true;
    }),
    body('username').custom((username) => {
        const errorMessage = validateRegistrationUsername(username);
        if (errorMessage) {
            throw new Error(errorMessage);
        }

        return true;
    }),
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
];

const loginValidation = [
    body('identifier').trim().notEmpty().withMessage('Username or email is required'),
    body('password').notEmpty().withMessage('Password is required'),
];

const resetPasswordValidation = [
    body('email').isEmail().normalizeEmail().withMessage('Valid email is required'),
    body('otp').trim().isLength({ min: 6, max: 6 }).isNumeric().withMessage('OTP must be a 6-digit number'),
    body('newPassword').notEmpty().withMessage('New password is required'),
];

const changePasswordValidation = [
    body('currentPassword').notEmpty().withMessage('Current password is required'),
    body('newPassword').custom((newPassword) => {
        const validation = validatePassword(newPassword);
        if (!validation.isValid) {
            throw new Error(validation.errors.join(' '));
        }
        return true;
    }),
];

const normalizeMoodleUser = (moodleUser) => {
    if (!moodleUser) return null;

    const fullNameFromParts = [moodleUser.firstname, moodleUser.lastname]
        .filter(Boolean)
        .join(' ')
        .trim();

    return {
        id: Number(moodleUser.id || moodleUser.userid || 0) || null,
        username: moodleUser.username || null,
        firstname: moodleUser.firstname || '',
        lastname: moodleUser.lastname || '',
        fullname: moodleUser.fullname || fullNameFromParts || moodleUser.username || '',
        email: moodleUser.email || moodleUser.useremail || null,
        profileimageurl:
            moodleUser.profileimageurl ||
            moodleUser.profileimageurlsmall ||
            moodleUser.userpictureurl ||
            null,
    };
};

const buildMoodleAuthCandidates = async (identifier) => {
    const candidates = [];

    const addCandidate = (value) => {
        if (typeof value !== 'string') return;
        const trimmed = value.trim();
        if (!trimmed) return;
        if (!candidates.includes(trimmed)) {
            candidates.push(trimmed);
        }
    };

    const rawIdentifier = typeof identifier === 'string' ? identifier.trim() : '';
    addCandidate(rawIdentifier);
    addCandidate(rawIdentifier.toLowerCase());

    if (rawIdentifier.includes('@')) {
        const userByEmail = normalizeMoodleUser(
            await moodleService.getUserByEmail(rawIdentifier)
        );
        if (userByEmail?.username) {
            addCandidate(userByEmail.username);
        }

        addCandidate(rawIdentifier.split('@')[0]);
    }

    return candidates;
};

const authenticateWithMoodleCandidates = async (identifier, password) => {
    const candidates = await buildMoodleAuthCandidates(identifier);

    for (const candidate of candidates) {
        const raw = await moodleService.authenticateWithPassword(candidate, password);
        const moodleUser = normalizeMoodleUser(raw);
        if (moodleUser?.id) {
            // Preserve the moodleToken from the raw response
            moodleUser.moodleToken = raw?.moodleToken || null;
            return moodleUser;
        }
    }

    return null;
};

const inferRole = (moodleUser) => {
    const username = String(moodleUser?.username || '').toLowerCase();
    if (username === 'admin' || Number(moodleUser?.id) === 2) return 'admin';
    return 'student';
};

const buildTokenPayload = (moodleUser) => {
    const role = inferRole(moodleUser);

    return {
        id: `moodle-${moodleUser.id}`,
        moodle_id: moodleUser.id,
        moodleId: moodleUser.id,
        name: moodleUser.fullname || moodleUser.username || 'Moodle User',
        username: moodleUser.username || null,
        email: moodleUser.email || null,
        role,
        avatar_url: moodleUser.profileimageurl || null,
        moodle_token: moodleUser.moodleToken || null,
    };
};

const generateToken = (payload) => {
    return jwt.sign(payload, process.env.JWT_SECRET, {
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
    });
};

const splitName = (name) => {
    const parts = String(name || '')
        .trim()
        .split(/\s+/)
        .filter(Boolean);

    const firstname = parts.shift() || 'Learner';
    const lastname = parts.length ? parts.join(' ') : 'User';

    return { firstname, lastname };
};

const isUsernameConflictError = (message) => {
    const normalized = String(message || '').toLowerCase();
    return (
        normalized.includes('username') &&
        (normalized.includes('already') ||
            normalized.includes('exists') ||
            normalized.includes('taken'))
    );
};

const isEmailConflictError = (message) => {
    const normalized = String(message || '').toLowerCase();
    return (
        normalized.includes('email') &&
        (normalized.includes('already') ||
            normalized.includes('exists') ||
            normalized.includes('used'))
    );
};

const PASSWORD_REQUIREMENTS = {
    minLength: 'At least 8 characters',
    minLowerCase: 'At least 1 lower case letter',
    minUpperCase: 'At least 1 upper case letter',
    minSpecialChar: 'At least 1 special character (*, -, #, !, @, $, %, ^, &, +, =, _, ~)',
};

// ─── Helper to extract and format validation errors ─────────────────────────────
const formatValidationErrors = (errors) => {
    const errorMessages = errors
        .array()
        .map((err) => err.msg)
        .filter(Boolean);

    return {
        error: errorMessages.join('\n') || 'Validation failed',
        details: errors.array(),
    };
};

const formatPasswordValidationErrors = (errorMessages) => {
    return {
        error: errorMessages.join('\n') || 'Password validation failed',
        passwordErrors: errorMessages,
        requirements: PASSWORD_REQUIREMENTS,
    };
};

const extractFieldErrors = (errors, fieldName) => {
    return errors
        .array()
        .filter((error) => error.path === fieldName || error.param === fieldName)
        .map((error) => error.msg)
        .filter(Boolean);
};

const findUserByEmail = async (email) => {
    return normalizeMoodleUser(await moodleService.getUserByEmail(email));
};

const findUserByUsername = async (username) => {
    return normalizeMoodleUser(await moodleService.getUserByUsername(username));
};

const checkEmailStatus = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json(formatValidationErrors(errors));
        }

        const normalizedEmail = String(req.body.email || '').trim().toLowerCase();
        const purpose = req.body.purpose === 'reset-password' ? 'reset-password' : 'register';
        const existingByEmail = await findUserByEmail(normalizedEmail);
        const exists = Boolean(existingByEmail?.id);

        if (purpose === 'register' && exists) {
            return res.status(409).json({
                error: 'An account with this email already exists.',
                exists: true,
                purpose,
            });
        }

        if (purpose === 'reset-password' && !exists) {
            return res.status(404).json({
                error: 'No account found with this email address.',
                exists: false,
                purpose,
            });
        }

        return res.status(200).json({
            email: normalizedEmail,
            exists,
            purpose,
        });
    } catch (error) {
        next(error);
    }
};

// ─── Step 1: Initiate registration — send OTP ─────────────────────────────────
const register = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            const usernameErrors = extractFieldErrors(errors, 'username');
            if (usernameErrors.length > 0) {
                return res.status(400).json({
                    error: usernameErrors.join('\n'),
                    usernameErrors,
                });
            }

            const nameErrors = extractFieldErrors(errors, 'name');
            if (nameErrors.length > 0) {
                return res.status(400).json({
                    error: nameErrors.join('\n'),
                    nameErrors,
                });
            }

            return res.status(400).json(formatValidationErrors(errors));
        }

        const { name, email, password, username } = req.body;
        const normalizedEmail = String(email || '').trim().toLowerCase();
        const normalizedUsername = normalizeRegistrationUsername(username);

        // Check Moodle for existing account
        const existingByEmail = await findUserByEmail(normalizedEmail);
        if (existingByEmail?.id) {
            return res.status(409).json({ error: 'An account with this email already exists.' });
        }

        const existingByUsername = await findUserByUsername(normalizedUsername);
        if (existingByUsername?.id) {
            return res.status(409).json({
                error: 'This username is already taken. Please choose another one.',
            });
        }

        const passwordValidation = validatePassword(password);
        if (!passwordValidation.isValid) {
            return res.status(400).json(
                formatPasswordValidationErrors(passwordValidation.errors)
            );
        }

        // Purge expired entries before adding a new one
        cleanExpiredOtps();

        const pendingByUsername = findPendingRegistrationByUsername(
            normalizedUsername,
            normalizedEmail
        );
        if (pendingByUsername) {
            return res.status(409).json({
                error: 'This username is currently waiting for verification. Please choose another one.',
            });
        }

        const otp = generateOtp();

        pendingRegistrations.set(normalizedEmail, {
            name: String(name || '').trim(),
            username: normalizedUsername,
            email: normalizedEmail,
            password,
            otp,
            expiresAt: Date.now() + OTP_TTL_MS,
            attempts: 0,
        });

        // Send OTP email
        try {
            await sendOtpEmail(
                normalizedEmail,
                otp,
                String(name || '').trim(),
                normalizedUsername
            );
        } catch (emailError) {
            pendingRegistrations.delete(normalizedEmail);
            console.error('OTP email send failed:', emailError.message);
            return res.status(500).json({
                error: 'Failed to send verification email. Please check your email address and try again.',
            });
        }

        return res.status(200).json({
            message: 'Verification code sent to your email. Please check your inbox.',
            email: normalizedEmail,
            username: normalizedUsername,
            otpSent: true,
        });
    } catch (error) {
        next(error);
    }
};

// ─── Step 2: Verify OTP and complete registration ─────────────────────────────
const verifyOtp = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error: 'Validation failed', details: errors.array() });
        }

        const { email, otp } = req.body;
        const normalizedEmail = String(email || '').trim().toLowerCase();

        const pending = pendingRegistrations.get(normalizedEmail);

        if (!pending) {
            return res.status(400).json({
                error: 'No pending registration found. Please register again.',
            });
        }

        if (Date.now() > pending.expiresAt) {
            pendingRegistrations.delete(normalizedEmail);
            return res.status(400).json({
                error: 'Verification code has expired. Please register again.',
            });
        }

        pending.attempts += 1;

        if (pending.attempts > OTP_MAX_ATTEMPTS) {
            pendingRegistrations.delete(normalizedEmail);
            return res.status(429).json({
                error: 'Too many incorrect attempts. Please register again.',
            });
        }

        if (otp.trim() !== pending.otp) {
            return res.status(400).json({
                error: `Invalid verification code. ${OTP_MAX_ATTEMPTS - pending.attempts} attempt(s) remaining.`,
            });
        }

        // OTP verified — create the account in Moodle
        const {
            name,
            username,
            password: pendingPassword,
        } = pending;
        pendingRegistrations.delete(normalizedEmail);

        const { firstname, lastname } = splitName(name);
        const normalizedUsername = normalizeRegistrationUsername(username);
        if (!normalizedUsername) {
            return res.status(400).json({
                error: 'Pending registration is missing a username. Please register again.',
            });
        }

        const existingByUsername = await findUserByUsername(normalizedUsername);
        if (existingByUsername?.id) {
            return res.status(409).json({
                error: 'This username is no longer available. Please register again with a different username.',
            });
        }

        let createdUser = null;
        try {
            createdUser = await moodleService.createUser({
                username: normalizedUsername,
                password: pendingPassword,
                firstname,
                lastname,
                email: normalizedEmail,
            });
        } catch (createError) {
            const message = String(createError?.message || '');

            if (isEmailConflictError(message)) {
                return res
                    .status(409)
                    .json({ error: 'An account with this email already exists.' });
            }

            if (isUsernameConflictError(message)) {
                return res.status(409).json({
                    error: 'This username is no longer available. Please register again with a different username.',
                });
            }

            return res
                .status(400)
                .json({ error: `Registration failed: ${message}` });
        }

        if (!createdUser) {
            return res.status(400).json({
                error: 'Registration failed: Unable to create user.',
            });
        }

        let moodleUser = null;
        if (createdUser?.id) {
            moodleUser = normalizeMoodleUser(await moodleService.getUserById(createdUser.id));
        }

        if (!moodleUser) {
            moodleUser = normalizeMoodleUser(await moodleService.getUserByEmail(normalizedEmail));
        }

        if (!moodleUser) {
            moodleUser = {
                id: Number(createdUser?.id || 0) || null,
                username: normalizedUsername,
                firstname,
                lastname,
                fullname: [firstname, lastname].filter(Boolean).join(' ').trim(),
                email: normalizedEmail,
                profileimageurl: null,
            };
        }

        // Authenticate with Moodle to get the user's personal token
        // so notifications and other user-scoped APIs work correctly
        try {
            const moodleAuth = await moodleService.authenticateWithPassword(
                moodleUser.username || normalizedUsername,
                pendingPassword
            );
            if (moodleAuth?.moodleToken) {
                moodleUser.moodleToken = moodleAuth.moodleToken;
            }
        } catch (_) {}

        const tokenPayload = buildTokenPayload(moodleUser);
        const token = generateToken(tokenPayload);

        // Send welcome email (non-blocking)
        try {
            await sendWelcomeEmail(
                normalizedEmail,
                [firstname, lastname].filter(Boolean).join(' ').trim(),
                moodleUser.username || normalizedUsername
            );
        } catch (emailError) {
            console.error('Welcome email send failed:', emailError.message);
            // Don't fail the registration if welcome email fails
        }

        return res.status(201).json({
            message: 'Registration successful',
            token,
            user: {
                id: tokenPayload.id,
                name: tokenPayload.name,
                username: tokenPayload.username,
                email: tokenPayload.email,
                role: tokenPayload.role,
                moodleId: tokenPayload.moodle_id,
                avatar_url: tokenPayload.avatar_url,
            },
        });
    } catch (error) {
        next(error);
    }
};

const login = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error: 'Validation failed', details: errors.array() });
        }

        const { identifier, password } = req.body;
        const moodleUser = await authenticateWithMoodleCandidates(identifier, password);

        if (!moodleUser) {
            return res.status(401).json({ error: 'Invalid username/email or password.' });
        }

        const tokenPayload = buildTokenPayload(moodleUser);
        const token = generateToken(tokenPayload);

        // Try to retrieve session key for AJAX endpoints
        // Session key can be obtained through an AJAX call after token authentication
        let sesskey = null;
        if (moodleUser?.moodleToken) {
            try {
                console.log(`[Auth] 🔑 Attempting to retrieve session key for ${tokenPayload.username}...`);
                const siteInfo = await moodleService.makeAjaxRequest(
                    'core_webservice_get_site_info',
                    {},
                    null  // No session key yet, using token-based auth
                );
                // AJAX requests might include sesskey in response or we can extract from headers
                // For now, mark as attempted
                console.log(`[Auth] ℹ️  Session key retrieval complete`);
            } catch (moodleErr) {
                console.warn(`[Auth] Could not retrieve session key:`, moodleErr.message);
                // Continue anyway - REST API is available as fallback
            }
        }

        console.log(`[Auth] ✅ Login successful for user ${tokenPayload.username}`);
        
        return res.json({
            message: 'Login successful',
            token,
            sesskey: sesskey,  // Can be null, REST API will be used as fallback
            user: {
                id: tokenPayload.id,
                name: tokenPayload.name,
                username: tokenPayload.username,
                email: tokenPayload.email,
                role: tokenPayload.role,
                moodleId: tokenPayload.moodle_id,
                avatar_url: tokenPayload.avatar_url,
            },
        });
    } catch (error) {
        next(error);
    }
};

// ─── Forgot Password: Step 1 — send OTP to email ─────────────────────────────
const forgotPassword = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json(formatValidationErrors(errors));
        }

        const normalizedEmail = String(req.body.email || '').trim().toLowerCase();

        const moodleUser = await findUserByEmail(normalizedEmail);
        if (!moodleUser?.id) {
            // Don't reveal whether email exists — generic response
            return res.status(200).json({
                message: 'If an account with that email exists, a reset code has been sent.',
                otpSent: true,
            });
        }

        const otp = generateOtp();
        pendingPasswordResets.set(normalizedEmail, {
            otp,
            expiresAt: Date.now() + OTP_TTL_MS,
            attempts: 0,
            moodleUserId: moodleUser.id,
            username: moodleUser.username || '',
            name: moodleUser.fullname || moodleUser.firstname || 'Learner',
        });

        try {
            await sendForgotPasswordOtpEmail(
                normalizedEmail,
                moodleUser.fullname || moodleUser.firstname || 'Learner',
                moodleUser.username || '',
                otp
            );
        } catch (emailErr) {
            pendingPasswordResets.delete(normalizedEmail);
            console.error('Forgot password OTP email failed:', emailErr.message);
            return res.status(500).json({ error: 'Failed to send reset email. Please try again.' });
        }

        return res.status(200).json({
            message: 'A password reset code has been sent to your email.',
            otpSent: true,
        });
    } catch (error) {
        next(error);
    }
};

// ─── Forgot Password: Step 2 — verify OTP + set new password ─────────────────
const resetPassword = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json(formatValidationErrors(errors));
        }

        const { email, otp, newPassword } = req.body;
        const normalizedEmail = String(email || '').trim().toLowerCase();

        const pending = pendingPasswordResets.get(normalizedEmail);
        if (!pending) {
            return res.status(400).json({
                error: 'No password reset request found. Please request a new code.',
            });
        }

        if (Date.now() > pending.expiresAt) {
            pendingPasswordResets.delete(normalizedEmail);
            return res.status(400).json({ error: 'Reset code has expired. Please request a new one.' });
        }

        pending.attempts += 1;
        if (pending.attempts > OTP_MAX_ATTEMPTS) {
            pendingPasswordResets.delete(normalizedEmail);
            return res.status(429).json({ error: 'Too many incorrect attempts. Please request a new code.' });
        }

        if (String(otp || '').trim() !== pending.otp) {
            return res.status(400).json({
                error: `Invalid code. ${OTP_MAX_ATTEMPTS - pending.attempts} attempt(s) remaining.`,
            });
        }

        // OTP valid — validate and apply new password
        const passwordValidation = validatePassword(newPassword);
        if (!passwordValidation.isValid) {
            return res.status(400).json(formatPasswordValidationErrors(passwordValidation.errors));
        }

        try {
            await moodleService.updateUserPassword(pending.moodleUserId, newPassword);
            pendingPasswordResets.delete(normalizedEmail);

            sendPasswordResetEmail(normalizedEmail, pending.name)
                .catch(err => console.error('Password reset confirmation email failed:', err.message));

            return res.json({ message: 'Password reset successfully.' });
        } catch (updateError) {
            console.error('Password update error:', updateError.message);
            return res.status(400).json({ error: `Password reset failed: ${updateError.message}` });
        }
    } catch (error) {
        next(error);
    }
};

const changePassword = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            const passwordErrors = extractFieldErrors(errors, 'newPassword');

            if (passwordErrors.length > 0) {
                return res.status(400).json(formatPasswordValidationErrors(passwordErrors));
            }

            return res.status(400).json(formatValidationErrors(errors));
        }

        const { currentPassword, newPassword } = req.body;
        const moodleId = req.user?.moodle_id || req.user?.moodleId;

        if (!moodleId) {
            return res.status(401).json({
                error: 'User not authenticated',
            });
        }

        // Check if current password matches (via Moodle)
        const moodleUser = normalizeMoodleUser(await moodleService.getUserById(moodleId));
        if (!moodleUser?.username) {
            return res.status(404).json({
                error: 'User not found',
            });
        }

        // Verify current password
        const verified = await moodleService.authenticateWithPassword(
            moodleUser.username,
            currentPassword
        );

        if (!verified) {
            return res.status(401).json({
                error: 'Current password is incorrect',
            });
        }

        // Update to new password
        try {
            await moodleService.updateUserPassword(moodleId, newPassword);

            // Notify user by email (non-blocking)
            if (moodleUser.email) {
                sendPasswordChangedEmail(moodleUser.email, moodleUser.fullname || moodleUser.firstname || 'Learner')
                    .catch((err) => console.error('Password changed email failed:', err.message));
            }

            return res.json({
                message: 'Password changed successfully',
            });
        } catch (updateError) {
            console.error('Password change error:', updateError.message);
            return res.status(400).json({
                error: `Password change failed: ${updateError.message}`,
            });
        }
    } catch (error) {
        next(error);
    }
};

module.exports = {
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
    forgotPasswordValidation: [body('email').isEmail().normalizeEmail().withMessage('Valid email is required')],
    resetPasswordValidation,
    changePasswordValidation,
};
