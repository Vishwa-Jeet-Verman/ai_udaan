const nodemailer = require('nodemailer');

const escapeHtml = (value) =>
  String(value ?? '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');

// Persistent pooled transporter — reuses connections instead of creating a new one per email
let _transporter = null;

const createTransporter = () => {
    const host = process.env.SMTP_HOST;
    const port = parseInt(process.env.SMTP_PORT || '587', 10);
    const user = process.env.SMTP_USER;
    const pass = process.env.SMTP_PASS;

    if (!host || !user || !pass) {
        throw new Error(
            'Email service not configured. Set SMTP_HOST, SMTP_USER, and SMTP_PASS in .env'
        );
    }

    if (!_transporter) {
        _transporter = nodemailer.createTransport({
            host,
            port,
            secure: port === 465,
            auth: { user, pass },
            pool: true,           // reuse connections
            maxConnections: 3,
            connectionTimeout: 10000,
            greetingTimeout: 10000,
            socketTimeout: 15000,
        });
    }

    return _transporter;
};

// Helper: send with automatic retry on transient failures
const sendWithRetry = async (mailOptions, retries = 2) => {
    for (let attempt = 1; attempt <= retries + 1; attempt++) {
        try {
            return await createTransporter().sendMail(mailOptions);
        } catch (err) {
            const isTransient = err.code === 'ECONNECTION' || err.code === 'ETIMEDOUT'
                || err.code === 'ECONNRESET' || String(err.message).includes('timeout');
            if (attempt <= retries && isTransient) {
                console.warn(`[Email] Attempt ${attempt} failed (${err.code}), retrying...`);
                await new Promise(r => setTimeout(r, 1000 * attempt));
                _transporter = null; // reset pool on connection error
            } else {
                throw err;
            }
        }
    }
};

/**
 * Send an OTP verification email to the user.
 * @param {string} toEmail   Recipient email address
 * @param {string} otp       6-digit OTP string
 * @param {string} name      Recipient's name for personalisation
 */
const sendOtpEmail = async (toEmail, otp, name = 'Learner', username = '') => {
    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;
    const appName = process.env.APP_NAME || 'NGTech LMS';
  const safeName = escapeHtml(name);
  const safeToEmail = escapeHtml(toEmail);
  const requestedUsername = String(username || '').trim() || 'Pending assignment';
  const safeRequestedUsername = escapeHtml(requestedUsername);

    await sendWithRetry({
        from: `"${appName}" <${fromAddress}>`,
        to: toEmail,
        subject: `Your ${appName} Verification Code`,
    text: `Hi ${name},\n\nYour ${appName} signup request was received successfully.\nUsername: ${requestedUsername}\nVerification code: ${otp}\n\nThis code expires in 10 minutes.\n\nIf you did not request this, please ignore this email.\n\n— ${appName} Team`,
        html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Verify your email</title>
</head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f5;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
          <!-- Header -->
          <tr>
            <td style="background:#4f46e5;padding:32px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:700;">${appName}</h1>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px;color:#374151;">
              <h2 style="margin:0 0 8px;font-size:20px;">Verify your email address</h2>
              <p style="margin:0 0 24px;color:#6b7280;font-size:15px;">
                Hi <strong>${safeName}</strong>, your signup request was received successfully. Use the code below to complete your registration.
              </p>

              <div style="background:#f9fafb;border-left:4px solid #4f46e5;padding:16px;margin:0 0 24px;border-radius:4px;">
                <p style="margin:0 0 8px;font-size:14px;color:#6b7280;text-transform:uppercase;letter-spacing:0.5px;font-weight:600;">Account Details</p>
                <p style="margin:0 0 8px;font-size:14px;"><strong>Username:</strong> <code style="background:#f0f0ff;padding:4px 8px;border-radius:4px;font-family:monospace;color:#4f46e5;">${safeRequestedUsername}</code></p>
                <p style="margin:0;font-size:14px;"><strong>Email:</strong> ${safeToEmail}</p>
              </div>

              <!-- OTP block -->
              <div style="text-align:center;margin:32px 0;">
                <span style="display:inline-block;background:#f0f0ff;border:2px dashed #4f46e5;
                             border-radius:8px;padding:16px 40px;
                             font-size:36px;font-weight:700;letter-spacing:10px;color:#4f46e5;">
                  ${otp}
                </span>
              </div>

              <p style="margin:0 0 8px;color:#6b7280;font-size:13px;text-align:center;">
                This code is valid for <strong>10 minutes</strong>.
              </p>
              <p style="margin:24px 0 0;color:#6b7280;font-size:13px;">
                If you did not create an account, you can safely ignore this email.
              </p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background:#f9fafb;padding:20px 40px;text-align:center;
                       color:#9ca3af;font-size:12px;border-top:1px solid #e5e7eb;">
              &copy; ${new Date().getFullYear()} ${appName}. All rights reserved.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    });
};

/**
 * Send a welcome email after successful account registration.
 * @param {string} toEmail   Recipient email address
 * @param {string} name      Recipient's name for personalisation
 * @param {string} username  Moodle username
 */
const sendWelcomeEmail = async (toEmail, name = 'Learner', username = '') => {
    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;
    const appName = process.env.APP_NAME || 'NGTech LMS';
  const safeName = escapeHtml(name);
  const safeToEmail = escapeHtml(toEmail);
  const resolvedUsername = String(username || '').trim() || 'Not set';
  const safeResolvedUsername = escapeHtml(resolvedUsername);

    await sendWithRetry({
        from: `"${appName}" <${fromAddress}>`,
        to: toEmail,
        subject: `Welcome to ${appName}! 🎓`,
    text: `Hi ${name},\n\nWelcome to ${appName}! Your account has been created successfully.\n\nUsername: ${resolvedUsername}\nEmail: ${toEmail}\n\nYou can now log in and start exploring courses.\n\nHappy learning!\n\n— ${appName} Team`,
        html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Welcome</title>
</head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f5;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg, #4f46e5 0%, #7c3aed 100%);padding:32px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:28px;font-weight:700;">Welcome! 🎓</h1>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px;color:#374151;">
              <p style="margin:0 0 16px;font-size:16px;">
                Hi <strong>${safeName}</strong>,
              </p>
              <p style="margin:0 0 24px;color:#6b7280;font-size:15px;line-height:1.6;">
                Welcome to <strong>${appName}</strong>! Your account has been successfully created.
                You're now ready to explore our courses and start your learning journey.
              </p>

              <!-- Account Details -->
              <div style="background:#f9fafb;border-left:4px solid #4f46e5;padding:16px;margin:28px 0;border-radius:4px;">
                <p style="margin:0 0 12px;font-size:14px;color:#6b7280;text-transform:uppercase;letter-spacing:0.5px;font-weight:600;">Account Details</p>
                <p style="margin:0 0 8px;font-size:14px;"><strong>Username:</strong> <code style="background:#f0f0ff;padding:4px 8px;border-radius:4px;font-family:monospace;color:#4f46e5;">${safeResolvedUsername}</code></p>
                <p style="margin:0;font-size:14px;"><strong>Email:</strong> ${safeToEmail}</p>
              </div>

              <p style="margin:24px 0 0;color:#6b7280;font-size:14px;line-height:1.6;">
                If you have any questions or need assistance, feel free to reach out to our support team.
              </p>
            </td>
          </tr>
          <!-- CTA -->
          <tr>
            <td style="padding:0 40px 32px;">
              <table width="100%" cellpadding="0" cellspacing="0">
                <tr>
                  <td align="center">
                    <a href="${process.env.BASE_URL || 'http://localhost:5000'}" style="display:inline-block;background:#4f46e5;color:#ffffff;padding:12px 32px;text-decoration:none;border-radius:6px;font-weight:600;font-size:15px;">
                      Start Learning
                    </a>
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background:#f9fafb;padding:20px 40px;text-align:center;
                       color:#9ca3af;font-size:12px;border-top:1px solid #e5e7eb;">
              &copy; ${new Date().getFullYear()} ${appName}. All rights reserved.
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    });
};

/**
 * Send a notification email after a successful password reset (forgot-password flow).
 * @param {string} toEmail  Recipient email address
 * @param {string} name     Recipient's display name
 */
const sendPasswordResetEmail = async (toEmail, name = 'Learner') => {
    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;
    const appName = process.env.APP_NAME || 'NGTech LMS';
    const time = new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });

    await sendWithRetry({
        from: `"${appName}" <${fromAddress}>`,
        to: toEmail,
        subject: `Your ${appName} password has been reset`,
        text: `Hi ${name},\n\nYour password was successfully reset on ${time}.\n\nIf you did not make this change, please contact support immediately.\n\n— ${appName} Team`,
        html: `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8" /><meta name="viewport" content="width=device-width,initial-scale=1.0" /></head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f5;padding:40px 0;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#4f46e5;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:700;">${appName}</h1>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;color:#374151;">
            <h2 style="margin:0 0 8px;font-size:20px;">Password Reset Successful</h2>
            <p style="margin:0 0 24px;color:#6b7280;font-size:15px;">
              Hi <strong>${name}</strong>, your account password was successfully reset.
            </p>
            <div style="background:#f0fdf4;border-left:4px solid #22c55e;padding:16px;margin:24px 0;border-radius:4px;">
              <p style="margin:0;font-size:14px;color:#15803d;">
                ✅ &nbsp;<strong>Password changed on:</strong> ${time}
              </p>
            </div>
            <div style="background:#fef2f2;border-left:4px solid #ef4444;padding:16px;margin:0;border-radius:4px;">
              <p style="margin:0;font-size:14px;color:#b91c1c;">
                ⚠️ &nbsp;If you did not request this, please contact support immediately.
              </p>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#f9fafb;padding:20px 40px;text-align:center;
                     color:#9ca3af;font-size:12px;border-top:1px solid #e5e7eb;">
            &copy; ${new Date().getFullYear()} ${appName}. All rights reserved.
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`,
    });
};

/**
 * Send a notification email after a password change from account settings.
 * @param {string} toEmail  Recipient email address
 * @param {string} name     Recipient's display name
 */
const sendPasswordChangedEmail = async (toEmail, name = 'Learner') => {
    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;
    const appName = process.env.APP_NAME || 'NGTech LMS';
    const time = new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });

    await sendWithRetry({
        from: `"${appName}" <${fromAddress}>`,
        to: toEmail,
        subject: `Your ${appName} password was changed`,
        text: `Hi ${name},\n\nYour account password was changed on ${time}.\n\nIf you did not make this change, please contact support immediately.\n\n— ${appName} Team`,
        html: `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8" /><meta name="viewport" content="width=device-width,initial-scale=1.0" /></head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f5;padding:40px 0;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#4f46e5;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:700;">${appName}</h1>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;color:#374151;">
            <h2 style="margin:0 0 8px;font-size:20px;">Password Changed</h2>
            <p style="margin:0 0 24px;color:#6b7280;font-size:15px;">
              Hi <strong>${name}</strong>, we're confirming that your password was just updated.
            </p>
            <div style="background:#f0fdf4;border-left:4px solid #22c55e;padding:16px;margin:24px 0;border-radius:4px;">
              <p style="margin:0;font-size:14px;color:#15803d;">
                ✅ &nbsp;<strong>Password updated on:</strong> ${time}
              </p>
            </div>
            <div style="background:#fef2f2;border-left:4px solid #ef4444;padding:16px;margin:0;border-radius:4px;">
              <p style="margin:0;font-size:14px;color:#b91c1c;">
                ⚠️ &nbsp;If you did not make this change, please contact support immediately.
              </p>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#f9fafb;padding:20px 40px;text-align:center;
                     color:#9ca3af;font-size:12px;border-top:1px solid #e5e7eb;">
            &copy; ${new Date().getFullYear()} ${appName}. All rights reserved.
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`,
    });
};

/**
 * Send a notification email after a profile name update.
 * @param {string} toEmail   Recipient email address
 * @param {string} name      Recipient's display name (for greeting)
 * @param {string} newName   The updated full name
 */
const sendProfileUpdatedEmail = async (toEmail, name = 'Learner', newName = '') => {
    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;
    const appName = process.env.APP_NAME || 'NGTech LMS';
    const time = new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });

    await sendWithRetry({
        from: `"${appName}" <${fromAddress}>`,
        to: toEmail,
        subject: `Your ${appName} profile has been updated`,
        text: `Hi ${name},\n\nYour profile was updated on ${time}.\n\nNew name: ${newName}\n\nIf you did not make this change, please contact support immediately.\n\n— ${appName} Team`,
        html: `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8" /><meta name="viewport" content="width=device-width,initial-scale=1.0" /></head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f5;padding:40px 0;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#4f46e5;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:700;">${appName}</h1>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;color:#374151;">
            <h2 style="margin:0 0 8px;font-size:20px;">Profile Updated</h2>
            <p style="margin:0 0 24px;color:#6b7280;font-size:15px;">
              Hi <strong>${name}</strong>, your profile has been updated successfully.
            </p>
            <div style="background:#f0fdf4;border-left:4px solid #22c55e;padding:16px;margin:24px 0;border-radius:4px;">
              <p style="margin:0 0 8px;font-size:14px;color:#15803d;">✅ &nbsp;<strong>Changes saved on:</strong> ${time}</p>
              <p style="margin:0;font-size:14px;color:#374151;"><strong>Updated name:</strong> ${newName}</p>
            </div>
            <div style="background:#fef2f2;border-left:4px solid #ef4444;padding:16px;margin:0;border-radius:4px;">
              <p style="margin:0;font-size:14px;color:#b91c1c;">
                ⚠️ &nbsp;If you did not make this change, please contact support immediately.
              </p>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#f9fafb;padding:20px 40px;text-align:center;
                     color:#9ca3af;font-size:12px;border-top:1px solid #e5e7eb;">
            &copy; ${new Date().getFullYear()} ${appName}. All rights reserved.
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`,
    });
};

/**
 * Send a support confirmation email to the user.
 * @param {string} toEmail   User's email address
 * @param {string} userName  User's name
 * @param {string} subject   Support ticket subject
 */
const sendSupportConfirmationEmail = async (toEmail, userName = 'Learner', subject = '') => {
    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;
    const appName = process.env.APP_NAME || 'NGTech LMS';
    const time = new Date().toLocaleString('en-IN', { timeZone: 'Asia/Kolkata' });

    await sendWithRetry({
        from: `"${appName} Support" <${fromAddress}>`,
        to: toEmail,
        subject: `✓ Your Support Request Received - ${appName}`,
        text: `Hi ${userName},\n\nThank you for contacting our support team!\n\nYour support request with subject "${subject}" has been successfully received.\n\nOur team will review your message and get back to you as soon as possible, typically within 24 hours.\n\nSubmitted on: ${time}\n\nWe appreciate your patience!\n\n— ${appName} Support Team`,
        html: `
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>Support Request Confirmed</title>
</head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f5;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0"
               style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
          <!-- Header -->
          <tr>
            <td style="background:linear-gradient(135deg, #10b981 0%, #059669 100%);padding:32px 40px;text-align:center;">
              <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:700;">✓ Request Received</h1>
            </td>
          </tr>
          <!-- Body -->
          <tr>
            <td style="padding:40px;color:#374151;">
              <p style="margin:0 0 16px;font-size:16px;">
                Hi <strong>${userName}</strong>,
              </p>
              <p style="margin:0 0 24px;color:#6b7280;font-size:15px;line-height:1.6;">
                Thank you for contacting our support team! Your feedback is important to us.
              </p>

              <!-- Status Box -->
              <div style="background:#f0fdf4;border-left:4px solid #10b981;padding:16px;margin:24px 0;border-radius:4px;">
                <p style="margin:0 0 12px;font-size:14px;color:#166534;text-transform:uppercase;letter-spacing:0.5px;font-weight:600;">✓ Status: Successfully Submitted</p>
                <p style="margin:0 0 8px;font-size:14px;"><strong>Subject:</strong> ${subject}</p>
                <p style="margin:0;font-size:14px;"><strong>Submitted on:</strong> ${time}</p>
              </div>

              <div style="background:#fef3c7;border-left:4px solid #f59e0b;padding:16px;margin:24px 0;border-radius:4px;">
                <p style="margin:0;font-size:14px;color:#92400e;">
                  ⏱️ &nbsp;Our team typically responds within <strong>24 hours</strong>. Please keep an eye on your inbox.
                </p>
              </div>

              <p style="margin:24px 0 0;color:#6b7280;font-size:14px;line-height:1.6;">
                If you have any urgent matters, you can reply to this email and we'll prioritize your request.
              </p>
            </td>
          </tr>
          <!-- Footer -->
          <tr>
            <td style="background:#f9fafb;padding:20px 40px;text-align:center;
                       color:#9ca3af;font-size:12px;border-top:1px solid #e5e7eb;">
              &copy; ${new Date().getFullYear()} ${appName}. All rights reserved.<br>
              <span style="color:#d1d5db;">Support Team: support@nighwantech.com</span>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>`,
    });
};

/**
 * Generic method to send any email with custom content.
 * @param {Object} options - Email options { to, subject, html, text, replyTo }
 */
const sendEmail = async (options) => {
    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;
    const appName = process.env.APP_NAME || 'NGTech LMS';

    if (!options.to || !options.subject) {
        throw new Error('Email requires "to" and "subject" fields');
    }

    await sendWithRetry({
        from: `"${appName}" <${fromAddress}>`,
        to: options.to,
        subject: options.subject,
        html: options.html || options.text,
        text: options.text || options.html,
        replyTo: options.replyTo || undefined,
    });
};

module.exports = { sendOtpEmail, sendWelcomeEmail, sendPasswordResetEmail, sendPasswordChangedEmail, sendProfileUpdatedEmail, sendForgotPasswordOtpEmail, sendEnrollmentEmail, sendSupportConfirmationEmail, sendEmail };

/**
 * Send a forgot-password OTP email with username reminder.
 */
async function sendForgotPasswordOtpEmail(toEmail, name = 'Learner', username = '', otp = '') {
    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;
    const appName = process.env.APP_NAME || 'NGTech LMS';
    const safeName = escapeHtml(name);
    const safeUsername = escapeHtml(username || 'N/A');

    await sendWithRetry({
        from: `"${appName}" <${fromAddress}>`,
        to: toEmail,
        subject: `Reset your ${appName} password`,
        text: `Hi ${name},\n\nYour username is: ${username}\n\nUse this code to reset your password: ${otp}\n\nThis code expires in 10 minutes.\n\nIf you did not request this, ignore this email.\n\n— ${appName} Team`,
        html: `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8" /><meta name="viewport" content="width=device-width,initial-scale=1.0" /></head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f5;padding:40px 0;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#4f46e5;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:700;">${appName}</h1>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;color:#374151;">
            <h2 style="margin:0 0 8px;font-size:20px;">Reset Your Password</h2>
            <p style="margin:0 0 24px;color:#6b7280;font-size:15px;">
              Hi <strong>${safeName}</strong>, we received a request to reset your password.
            </p>
            <div style="background:#f9fafb;border-left:4px solid #4f46e5;padding:16px;margin:0 0 24px;border-radius:4px;">
              <p style="margin:0 0 8px;font-size:14px;color:#6b7280;text-transform:uppercase;letter-spacing:0.5px;font-weight:600;">Your Account</p>
              <p style="margin:0;font-size:14px;"><strong>Username:</strong> <code style="background:#f0f0ff;padding:4px 8px;border-radius:4px;font-family:monospace;color:#4f46e5;">${safeUsername}</code></p>
            </div>
            <p style="margin:0 0 12px;color:#374151;font-size:14px;text-align:center;">Use this code to reset your password:</p>
            <div style="text-align:center;margin:0 0 24px;">
              <span style="display:inline-block;background:#f0f0ff;border:2px dashed #4f46e5;
                           border-radius:8px;padding:16px 40px;
                           font-size:36px;font-weight:700;letter-spacing:10px;color:#4f46e5;">
                ${otp}
              </span>
            </div>
            <p style="margin:0 0 8px;color:#6b7280;font-size:13px;text-align:center;">
              This code is valid for <strong>10 minutes</strong>.
            </p>
            <div style="background:#fef2f2;border-left:4px solid #ef4444;padding:12px 16px;margin:24px 0 0;border-radius:4px;">
              <p style="margin:0;font-size:13px;color:#b91c1c;">
                ⚠️ If you did not request a password reset, ignore this email — your password will not change.
              </p>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#f9fafb;padding:20px 40px;text-align:center;
                     color:#9ca3af;font-size:12px;border-top:1px solid #e5e7eb;">
            &copy; ${new Date().getFullYear()} ${appName}. All rights reserved.
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`,
    });
}

/**
 * Send a course enrollment confirmation email.
 */
async function sendEnrollmentEmail(toEmail, name = 'Learner', courseName = '') {
    const fromAddress = process.env.SMTP_FROM || process.env.SMTP_USER;
    const appName = process.env.APP_NAME || 'NGTech LMS';
    const safeName = escapeHtml(name);
    const safeCourseName = escapeHtml(courseName);

    await sendWithRetry({
        from: `"${appName}" <${fromAddress}>`,
        to: toEmail,
        subject: `🎉 You're enrolled in ${courseName} — ${appName}`,
        text: `Hi ${name},\n\nCongratulations! You have been successfully enrolled in "${courseName}".\n\nOpen the ${appName} app to start learning.\n\n— ${appName} Team`,
        html: `
<!DOCTYPE html>
<html>
<head><meta charset="utf-8" /><meta name="viewport" content="width=device-width,initial-scale=1.0" /></head>
<body style="margin:0;padding:0;background:#f4f4f5;font-family:Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#f4f4f5;padding:40px 0;">
    <tr><td align="center">
      <table width="480" cellpadding="0" cellspacing="0"
             style="background:#ffffff;border-radius:12px;overflow:hidden;box-shadow:0 2px 8px rgba(0,0,0,0.08);">
        <tr>
          <td style="background:#4f46e5;padding:32px 40px;text-align:center;">
            <h1 style="margin:0;color:#ffffff;font-size:24px;font-weight:700;">${appName}</h1>
          </td>
        </tr>
        <tr>
          <td style="padding:40px;color:#374151;">
            <h2 style="margin:0 0 8px;font-size:22px;">🎉 Enrollment Confirmed!</h2>
            <p style="margin:0 0 24px;color:#6b7280;font-size:15px;">
              Hi <strong>${safeName}</strong>, you have been successfully enrolled in:
            </p>
            <div style="background:#f0f0ff;border-left:4px solid #4f46e5;padding:20px;margin:0 0 24px;border-radius:6px;text-align:center;">
              <p style="margin:0;font-size:18px;font-weight:700;color:#4f46e5;">${safeCourseName}</p>
            </div>
            <p style="margin:0 0 24px;color:#6b7280;font-size:14px;">
              Open the <strong>${appName}</strong> app and go to <em>My Courses</em> to start learning right away.
            </p>
            <div style="background:#f0fdf4;border-left:4px solid #22c55e;padding:12px 16px;border-radius:4px;">
              <p style="margin:0;font-size:13px;color:#15803d;">
                ✅ Your enrollment is active. Happy learning!
              </p>
            </div>
          </td>
        </tr>
        <tr>
          <td style="background:#f9fafb;padding:20px 40px;text-align:center;
                     color:#9ca3af;font-size:12px;border-top:1px solid #e5e7eb;">
            &copy; ${new Date().getFullYear()} ${appName}. All rights reserved.
          </td>
        </tr>
      </table>
    </td></tr>
  </table>
</body>
</html>`,
    });
}
