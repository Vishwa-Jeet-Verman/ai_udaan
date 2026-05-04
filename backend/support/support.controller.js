const EmailService = require('../services/email.service');

exports.sendSupportEmail = async (req, res, next) => {
    try {
        const { userEmail, userName, subject, message } = req.body;

        if (!userEmail?.trim() || !userName?.trim() || !subject?.trim() || !message?.trim()) {
            return res.status(400).json({ error: 'All fields are required.' });
        }

        const adminEmail = process.env.SMTP_FROM || 'ngtechlms@nighwantech.com';

        console.log(`[Support] 📧 Sending support email:`);
        console.log(`           From: ${userEmail}`);
        console.log(`           To: ${adminEmail}`);
        console.log(`           User: ${userName}`);
        console.log(`           Subject: ${subject}`);

        // Send email to admin
        await EmailService.sendEmail({
            to: adminEmail,
            subject: `[Support] ${subject} - From: ${userName}`,
            html: `
                <h2>New Support Request</h2>
                <p><strong>User Name:</strong> ${userName}</p>
                <p><strong>User Email:</strong> ${userEmail}</p>
                <p><strong>Subject:</strong> ${subject}</p>
                <hr />
                <p><strong>Message:</strong></p>
                <p>${message.replace(/\n/g, '<br>')}</p>
                <hr />
                <p style="color: #666; font-size: 12px;">
                    <em>Reply to: ${userEmail}</em>
                </p>
            `,
        });

        console.log(`[Support] ✅ Support email sent to admin successfully`);

        // Send confirmation email to user
        await EmailService.sendSupportConfirmationEmail(userEmail, userName, subject);

        console.log(`[Support] ✅ Confirmation email sent to user successfully`);

        res.status(201).json({
            success: true,
            message: 'Support request sent successfully. You will receive a confirmation email shortly. Admin will reply to your email.',
        });
    } catch (err) {
        console.error(`[Support] ❌ Failed to send support email:`, err.message);
        res.status(500).json({
            error: 'Failed to send support request',
            message: err.message,
        });
    }
};
