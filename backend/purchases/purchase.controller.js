const moodleService = require('../services/moodle.service');
const notifService = require('../notifications/notification.service');
const { sendEnrollmentEmail } = require('../services/email.service');

const isMoodleCourseId = (value) => /^\d+$/.test(String(value || ''));

const resolveMoodleUserId = async (user) => {
    if (!user) return null;
    if (user.moodle_id) return Number(user.moodle_id) || user.moodle_id;

    const resolvedMoodleUser = await moodleService.resolveMoodleUserForLocalUser(user);
    return resolvedMoodleUser?.id || null;
};

const mapMoodleCourseToEnrollment = ({ user, course, enrolledAt }) => ({
    id: `moodle-${user.id}-${course.id}`,
    user_id: user.id,
    course_id: String(course.id),
    enrolled_at: enrolledAt || new Date().toISOString(),
    transaction_status: 'approved',
    course: moodleService.mapCourseToApi(course),
});

const enrollInCourse = async (req, res, next) => {
    try {
        const { courseId } = req.params;
        console.log(`[Enroll] 📝 Enrollment request for user ${req.user?.id}, course ${courseId}`);

        if (!isMoodleCourseId(courseId)) {
            console.log(`[Enroll] ❌ Invalid course ID: ${courseId}`);
            return res.status(404).json({ error: 'Course not found in Moodle.' });
        }

        const moodleCourse = await moodleService.getCourseById(Number(courseId));
        if (!moodleCourse) {
            console.log(`[Enroll] ❌ Course not found in Moodle: ${courseId}`);
            return res.status(404).json({ error: 'Course not found.' });
        }

        const moodleUserId = await resolveMoodleUserId(req.user);
        if (!moodleUserId) {
            console.log(`[Enroll] ❌ Could not resolve Moodle user ID for user ${req.user?.id}`);
            return res.status(403).json({
                error: 'Unable to resolve Moodle user for this account.',
            });
        }

        console.log(`[Enroll] 🔍 Checking if user ${moodleUserId} is already enrolled...`);
        const enrolled = await moodleService.isUserEnrolledInCourse(moodleUserId, courseId);
        if (enrolled) {
            console.log(`[Enroll] ℹ️ User ${moodleUserId} already enrolled in course ${courseId}`);
            return res.status(200).json({
                message: 'Enrollment verified from Moodle.',
                enrollment: mapMoodleCourseToEnrollment({ user: req.user, course: moodleCourse }),
            });
        }

        let enrolledNow = false;
        try {
            console.log(`[Enroll] 🔐 Attempting to enroll user ${moodleUserId} in course ${courseId}...`);
            // Pass the user's own Moodle token so self-enrolment runs as the student
            const userMoodleToken = req.user?.moodle_token || null;
            enrolledNow = await moodleService.enrollUserInCourse(moodleUserId, courseId, userMoodleToken);
            console.log(`[Enroll] ✅ Enrollment result: ${enrolledNow}`);
        } catch (enrollError) {
            console.error(`[Enroll] ❌ Enrollment error:`, enrollError.message);
            const msg = enrollError.message || '';
            const userFriendly = msg.toLowerCase().includes('no active self-enrolment')
                ? 'Enrolment is not enabled for this course yet. Please contact the admin.'
                : `Unable to enroll: ${msg}`;
            return res.status(400).json({ error: userFriendly });
        }

        if (!enrolledNow) {
            console.log(`[Enroll] ⚠️ Enrollment returned false for user ${moodleUserId}, course ${courseId}`);
            return res.status(502).json({
                error:
                    'Enrollment request was sent to Moodle but could not be confirmed yet. Please try again.',
            });
        }

        console.log(`[Enroll] 📧 Sending enrollment notification and email...`);
        // Push welcome notification — persisted in local store + real-time socket
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
            // If email not in JWT, fetch from Moodle
            if (!email && moodleUserId) {
                try {
                    const moodleUser = await moodleService.getUserById(moodleUserId);
                    email = moodleUser?.email || null;
                } catch (_) {}
            }
            if (!email) {
                console.warn('[Enroll] ⚠️ No email found — skipping enrollment email');
                return;
            }
            console.log('[Enroll] Sending email to:', email);
            await sendEnrollmentEmail(email, userName, courseName);
            console.log('[Enroll] ✅ Email sent to', email);
        };

        sendEmail().catch(err => console.error('[Enroll] ❌ Email failed:', err.message));

        console.log(`[Enroll] ✅ Successfully enrolled user ${moodleUserId} in course ${courseId}`);
        return res.status(201).json({
            message: 'Enrolled successfully.',
            enrollment: mapMoodleCourseToEnrollment({
                user: req.user,
                course: moodleCourse,
                enrolledAt: new Date().toISOString(),
            }),
        });
    } catch (error) {
        console.error(`[Enroll] ❌ Unexpected error during enrollment:`, error);
        next(error);
    }
};

const listEnrollments = async (req, res, next) => {
    try {
        const moodleUserId = await resolveMoodleUserId(req.user);
        if (!moodleUserId) {
            return res.json({ enrollments: [] });
        }

        const moodleCourses = await moodleService.getUserCourses(moodleUserId);
        const allMoodleCourses = await moodleService.getAllCourses();
        const moodleCoursesById = new Map(
            allMoodleCourses.map((course) => [String(course?.id || ''), course])
        );

        const enrollments = moodleCourses.map((course) =>
            mapMoodleCourseToEnrollment({
                user: req.user,
                course: moodleCoursesById.get(String(course?.id || '')) || course,
            })
        );

        return res.json({ enrollments });
    } catch (error) {
        next(error);
    }
};

const checkEnrollment = async (req, res, next) => {
    try {
        const { courseId } = req.params;

        if (!isMoodleCourseId(courseId)) {
            return res.status(404).json({ error: 'Course not found in Moodle.' });
        }

        const moodleCourse = await moodleService.getCourseById(Number(courseId));
        if (!moodleCourse) {
            return res.status(404).json({ error: 'Course not found.' });
        }

        const moodleUserId = await resolveMoodleUserId(req.user);
        if (!moodleUserId) {
            return res.json({ enrolled: false });
        }

        const enrolled = await moodleService.isUserEnrolledInCourse(moodleUserId, courseId);
        return res.json({ enrolled: !!enrolled });
    } catch (error) {
        next(error);
    }
};

const unenroll = async (req, res, next) => {
    try {
        const { courseId } = req.params;

        if (!isMoodleCourseId(courseId)) {
            return res.status(404).json({ error: 'Course not found in Moodle.' });
        }

        const moodleCourse = await moodleService.getCourseById(Number(courseId));
        if (!moodleCourse) {
            return res.status(404).json({ error: 'Course not found.' });
        }

        const moodleUserId = await resolveMoodleUserId(req.user);
        if (!moodleUserId) {
            return res.status(404).json({ error: 'Enrollment not found.' });
        }

        const enrolledInMoodle = await moodleService.isUserEnrolledInCourse(moodleUserId, courseId);
        if (enrolledInMoodle) {
            return res.status(400).json({
                error: 'Moodle enrollments must be managed in Moodle.',
            });
        }

        return res.status(404).json({ error: 'Enrollment not found.' });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    enrollInCourse,
    listEnrollments,
    checkEnrollment,
    unenroll,
};
