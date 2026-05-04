const { body, validationResult } = require('express-validator');
const moodleService = require('../services/moodle.service');

const isMoodleCourseId = (value) => /^\d+$/.test(String(value || ''));

const paginate = (items, page, limit) => {
    const total = items.length;
    const totalPages = Math.max(1, Math.ceil(total / limit));
    const safePage = Math.min(Math.max(page, 1), totalPages);
    const start = (safePage - 1) * limit;

    return {
        rows: items.slice(start, start + limit),
        total,
        totalPages,
        page: safePage,
        limit,
    };
};

const resolveMoodleUserId = async (user) => {
    if (!user) return null;
    if (user.moodle_id) return Number(user.moodle_id) || user.moodle_id;

    const resolvedMoodleUser = await moodleService.resolveMoodleUserForLocalUser(user);
    return resolvedMoodleUser?.id || null;
};

const courseValidation = [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('description').optional().trim(),
    body('price').optional().isFloat({ min: 0 }).withMessage('Price must be a positive number'),
    body('thumbnail_url').optional().trim(),
];

const createCourse = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error: 'Validation failed', details: errors.array() });
        }

        return res.status(400).json({
            error: 'Course creation is managed in Moodle. Please create courses in Moodle.',
        });
    } catch (error) {
        next(error);
    }
};

const listCourses = async (req, res, next) => {
    try {
        const page = parseInt(req.query.page, 10) || 1;
        const limit = parseInt(req.query.limit, 10) || 20;

        const moodleCourses = await moodleService.getAllCourses();
        const mappedCourses = moodleCourses
            .map((course) => moodleService.mapCourseToApi(course))
            .sort((a, b) => Number(b.id || 0) - Number(a.id || 0));

        const paginated = paginate(mappedCourses, page, limit);

        return res.json({
            courses: paginated.rows,
            pagination: {
                total: paginated.total,
                page: paginated.page,
                limit: paginated.limit,
                totalPages: paginated.totalPages,
            },
        });
    } catch (error) {
        next(error);
    }
};

const getCourse = async (req, res, next) => {
    try {
        const { id } = req.params;

        if (!isMoodleCourseId(id)) {
            return res.status(404).json({ error: 'Course not found in Moodle.' });
        }

        const moodleCourse = await moodleService.getCourseById(Number(id));
        if (!moodleCourse) {
            return res.status(404).json({ error: 'Course not found.' });
        }

        let isEnrolled = false;
        if (req.user?.role === 'admin') {
            isEnrolled = true;
        } else if (req.user) {
            const moodleUserId = await resolveMoodleUserId(req.user);
            if (moodleUserId) {
                isEnrolled = await moodleService.isUserEnrolledInCourse(moodleUserId, id);
            }
        }

        const contents = await moodleService.getCourseContents(Number(id));
        const lessonCount = contents.reduce((count, section) => {
            const modules = Array.isArray(section?.modules) ? section.modules : [];
            return count + modules.length;
        }, 0);

        return res.json({
            course: moodleService.mapCourseToApi(moodleCourse),
            isEnrolled,
            lessonCount,
        });
    } catch (error) {
        next(error);
    }
};

const updateCourse = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error: 'Validation failed', details: errors.array() });
        }

        return res.status(400).json({
            error: 'Course updates are managed in Moodle. Please edit courses in Moodle.',
        });
    } catch (error) {
        next(error);
    }
};

const deleteCourse = async (_req, res) => {
    return res.status(400).json({
        error: 'Course deletion is managed in Moodle. Please delete courses in Moodle.',
    });
};

const listMyCourses = async (req, res, next) => {
    try {
        const moodleUserId = await resolveMoodleUserId(req.user);
        if (!moodleUserId) {
            return res.json({ courses: [] });
        }

        const moodleCourses = await moodleService.getUserCourses(moodleUserId);
        const allMoodleCourses = await moodleService.getAllCourses();
        const moodleCoursesById = new Map(
            allMoodleCourses.map((course) => [String(course?.id || ''), course])
        );

        return res.json({
            courses: moodleCourses.map((course) =>
                moodleService.mapCourseToApi(
                    moodleCoursesById.get(String(course?.id || '')) || course
                )
            ),
        });
    } catch (error) {
        next(error);
    }
};

module.exports = {
    createCourse,
    listCourses,
    getCourse,
    listMyCourses,
    updateCourse,
    deleteCourse,
    courseValidation,
};
