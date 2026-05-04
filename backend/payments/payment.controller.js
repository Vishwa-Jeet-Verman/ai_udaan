const Razorpay = require('razorpay');
const crypto = require('crypto');
const moodleService = require('../services/moodle.service');
const notifService = require('../notifications/notification.service');
const { sendEnrollmentEmail } = require('../services/email.service');

const razorpay = new Razorpay({
    key_id: process.env.RAZORPAY_KEY_ID,
    key_secret: process.env.RAZORPAY_KEY_SECRET,
});

const resolveMoodleUserId = async (user) => {
    if (!user) return null;
    if (user.moodle_id) return Number(user.moodle_id) || user.moodle_id;

    const resolvedMoodleUser = await moodleService.resolveMoodleUserForLocalUser(user);
    return resolvedMoodleUser?.id || null;
};

/**
 * Create a Razorpay order for course enrollment
 */
const createOrder = async (req, res, next) => {
    try {
        const { courseId } = req.params;
        console.log(`[Payment] 📝 Creating order for user ${req.user?.id}, course ${courseId}`);

        // Get course details
        const moodleCourse = await moodleService.getCourseById(Number(courseId));
        if (!moodleCourse) {
            return res.status(404).json({ error: 'Course not found.' });
        }

        const mappedCourse = moodleService.mapCourseToApi(moodleCourse);
        
        // Check if course is free
        if (mappedCourse.price === 0) {
            return res.status(400).json({ error: 'This course is free. No payment required.' });
        }

        // Check if already enrolled
        const moodleUserId = await resolveMoodleUserId(req.user);
        if (moodleUserId) {
            const enrolled = await moodleService.isUserEnrolledInCourse(moodleUserId, courseId);
            if (enrolled) {
                return res.status(400).json({ error: 'Already enrolled in this course.' });
            }
        }

        // Create Razorpay order
        const amount = Math.round(mappedCourse.price * 100); // Convert to paise
        const options = {
            amount,
            currency: 'INR',
            receipt: `course_${courseId}_user_${req.user.id}_${Date.now()}`,
            notes: {
                courseId,
                userId: req.user.id,
                courseName: mappedCourse.title,
            },
        };

        const order = await razorpay.orders.create(options);
        console.log(`[Payment] ✅ Order created: ${order.id}`);

        return res.json({
            orderId: order.id,
            amount: order.amount,
            currency: order.currency,
            keyId: process.env.RAZORPAY_KEY_ID,
        });
    } catch (error) {
        console.error(`[Payment] ❌ Error creating order:`, error);
        next(error);
    }
};

/**
 * Verify payment and enroll user in course
 */
const verifyPayment = async (req, res, next) => {
    try {
        const { courseId } = req.params;
        const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;

        console.log(`[Payment] 🔍 Verifying payment for course ${courseId}`);

        if (!razorpay_order_id || !razorpay_payment_id || !razorpay_signature) {
            return res.status(400).json({ error: 'Missing payment details.' });
        }

        // Verify signature
        const body = razorpay_order_id + '|' + razorpay_payment_id;
        const expectedSignature = crypto
            .createHmac('sha256', process.env.RAZORPAY_KEY_SECRET)
            .update(body.toString())
            .digest('hex');

        if (expectedSignature !== razorpay_signature) {
            console.log(`[Payment] ❌ Invalid signature`);
            return res.status(400).json({ error: 'Invalid payment signature.' });
        }

        console.log(`[Payment] ✅ Payment verified successfully`);

        // Get course details
        const moodleCourse = await moodleService.getCourseById(Number(courseId));
        if (!moodleCourse) {
            return res.status(404).json({ error: 'Course not found.' });
        }

        // Enroll user in course
        const moodleUserId = await resolveMoodleUserId(req.user);
        if (!moodleUserId) {
            return res.status(403).json({
                error: 'Unable to resolve Moodle user for this account.',
            });
        }

        console.log(`[Payment] 🔐 Enrolling user ${moodleUserId} in course ${courseId}...`);
        const userMoodleToken = req.user?.moodle_token || null;
        const enrolledNow = await moodleService.enrollUserInCourse(moodleUserId, courseId, userMoodleToken);

        if (!enrolledNow) {
            return res.status(502).json({
                error: 'Payment successful but enrollment failed. Please contact support.',
            });
        }

        console.log(`[Payment] 📧 Sending enrollment notification and email...`);
        
        // Push welcome notification
        notifService.push(req.app, req.user.id, {
            type: 'enrollment',
            title: `Welcome to ${moodleCourse.fullname || moodleCourse.shortname}! 🎉`,
            body: `You now have access to "${moodleCourse.fullname || moodleCourse.shortname}". Start your learning journey today!`,
            data: { courseId: String(courseId) },
        });

        // Send confirmation email (non-blocking)
        const userEmail = req.user.email || null;
        const userName = req.user.name || req.user.username || 'Learner';
        const courseName = moodleCourse.fullname || moodleCourse.shortname || 'the course';

        const sendEmail = async () => {
            let email = userEmail;
            if (!email && moodleUserId) {
                try {
                    const moodleUser = await moodleService.getUserById(moodleUserId);
                    email = moodleUser?.email || null;
                } catch (_) {}
            }
            if (!email) {
                console.warn('[Payment] ⚠️ No email found — skipping enrollment email');
                return;
            }
            await sendEnrollmentEmail(email, userName, courseName);
            console.log('[Payment] ✅ Email sent to', email);
        };

        sendEmail().catch(err => console.error('[Payment] ❌ Email failed:', err.message));

        console.log(`[Payment] ✅ Successfully enrolled user ${moodleUserId} in course ${courseId}`);
        
        return res.status(200).json({
            success: true,
            message: 'Payment verified and enrolled successfully.',
            enrollment: {
                id: `moodle-${req.user.id}-${courseId}`,
                user_id: req.user.id,
                course_id: String(courseId),
                enrolled_at: new Date().toISOString(),
                transaction_status: 'approved',
                payment_id: razorpay_payment_id,
                order_id: razorpay_order_id,
            },
        });
    } catch (error) {
        console.error(`[Payment] ❌ Error verifying payment:`, error);
        next(error);
    }
};

module.exports = {
    createOrder,
    verifyPayment,
};
