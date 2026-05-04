const moodleService = require('../services/moodle.service');

/**
 * Fetch grade items for a user across all their enrolled courses.
 * Uses Moodle's gradereport_user_get_grade_items web service.
 */
const getGrades = async (req, res, next) => {
    try {
        const moodleUserId = req.user?.moodle_id;
        if (!moodleUserId) {
            return res.status(403).json({ error: 'Moodle account required to view grades.' });
        }

        const enrolledCourses = await moodleService.getUserCourses(moodleUserId);
        if (!enrolledCourses.length) {
            return res.json({ grades: [] });
        }

        const grades = [];

        for (const course of enrolledCourses) {
            const courseId = course.id;
            const courseTitle = course.displayname || course.fullname || `Course ${courseId}`;

            let gradeItems = [];
            let courseTotal = null;

            try {
                const result = await moodleService.makeRequest(
                    'gradereport_user_get_grade_items',
                    { courseid: courseId, userid: moodleUserId }
                );

                // Response shape: { usergrades: [{ gradeitems: [...], userfullname, ... }] }
                const userGrades = result?.usergrades?.[0];
                if (userGrades) {
                    const items = Array.isArray(userGrades.gradeitems) ? userGrades.gradeitems : [];

                    for (const item of items) {
                        const isCourseTotal = item.itemtype === 'course';
                        const gradeEntry = {
                            id: String(item.id),
                            itemname: item.itemname || (isCourseTotal ? 'Course Total' : 'Unnamed'),
                            itemtype: item.itemtype || 'mod',
                            itemmodule: item.itemmodule || null,
                            graderaw: item.graderaw ?? null,
                            grademin: item.grademin ?? 0,
                            grademax: item.grademax ?? 100,
                            gradeformatted: item.gradeformatted || '-',
                            percentageformatted: item.percentageformatted || null,
                            feedback: item.feedback || null,
                        };

                        if (isCourseTotal) {
                            courseTotal = gradeEntry;
                        } else {
                            gradeItems.push(gradeEntry);
                        }
                    }
                }
            } catch (err) {
                // Grade report may not be enabled — skip silently
                console.warn(`[Grades] Could not fetch grades for course ${courseId}:`, err.message);
            }

            grades.push({
                courseId: String(courseId),
                courseTitle,
                courseTotal,
                items: gradeItems,
            });
        }

        return res.json({ grades });
    } catch (error) {
        next(error);
    }
};

module.exports = { getGrades };
