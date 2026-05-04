const { body, validationResult } = require('express-validator');
const { upload } = require('../storage/storage.service');
const moodleService = require('../services/moodle.service');

const isMoodleCourseId = (value) => /^\d+$/.test(String(value || ''));

const parseMoodleLessonId = (value) => {
    const match = /^moodle-(\d+)-(\d+)$/.exec(String(value || ''));
    if (!match) return null;
    return {
        courseId: Number(match[1]),
        moduleId: Number(match[2]),
    };
};

const inferLessonType = (module) => {
    const modname = (module?.modname || '').toLowerCase();

    // label modules with embedded video in description
    if (modname === 'label') {
        const desc = module?.description || '';
        if (desc.includes('<video') || desc.includes('<source') ||
            /\.(mp4|webm|mov|m4v)/i.test(desc)) return 'video';
        if (/\.(pdf)/i.test(desc)) return 'pdf';
    }

    if (modname === 'url') {
        const externalUrl = (module?.url || '').toLowerCase();
        if (
            externalUrl.includes('youtube.com') ||
            externalUrl.includes('youtu.be') ||
            externalUrl.includes('vimeo.com') ||
            externalUrl.includes('drive.google.com')
        ) {
            return 'video';
        }
    }

    const contents = Array.isArray(module?.contents) ? module.contents : [];
    const content = contents.find((item) => !!item?.filename) || contents[0];

    const filename = String(content?.filename || '').toLowerCase();
    const mimetype = String(content?.mimetype || '').toLowerCase();

    if (filename.endsWith('.pdf') || mimetype.includes('pdf')) return 'pdf';
    if (
        mimetype.includes('video') ||
        filename.endsWith('.mp4') ||
        filename.endsWith('.webm') ||
        filename.endsWith('.mov') ||
        filename.endsWith('.m4v')
    ) return 'video';

    return 'video';
};

const resolveModuleFileUrl = (module) => {
    const contents = Array.isArray(module?.contents) ? module.contents : [];
    const contentWithFile = contents.find((item) => !!item?.fileurl);
    if (contentWithFile?.fileurl) return contentWithFile.fileurl;
    if (module?.url) return module.url;

    // label modules embed video/content in description HTML — extract src URL
    const description = module?.description || '';
    if (description) {
        // Match <source src="..."> or <video src="...">
        const srcMatch = description.match(/<source[^>]+src=["']([^"']+)["']/i)
            || description.match(/<video[^>]+src=["']([^"']+)["']/i);
        if (srcMatch) return srcMatch[1];

        // Match <a href="..."> for linked files
        const hrefMatch = description.match(/<a[^>]+href=["']([^"']+\.(mp4|webm|mov|pdf))["']/i);
        if (hrefMatch) return hrefMatch[1];
    }

    return '';
};

const mapMoodleModuleToLesson = ({
    courseId,
    module,
    courseTitle,
    sortOrder,
    sectionName,
    sectionId,
}) => {
    const fileUrl = resolveModuleFileUrl(module);

    let title = (module?.name || '').trim();
    if (!title && sectionName) {
        title = `${sectionName} - Module ${module.id}`;
    }
    if (!title) {
        title = 'Untitled lesson';
    }

    return {
        id: `moodle-${courseId}-${module.id}`,
        course_id: String(courseId),
        title,
        section_name: sectionName || null,
        section_id: sectionId || null,
        module_name: module?.modname || null,
        description: module?.description || null,
        type: inferLessonType(module),
        file_url: moodleService.appendTokenToUrl(fileUrl),
        sort_order: sortOrder,
        signed_url: moodleService.appendTokenToUrl(fileUrl),
        content_status: 'approved',
        created_at: null,
        course: {
            id: String(courseId),
            title: courseTitle,
        },
    };
};

const resolveMoodleUserId = async (user) => {
    if (!user) return null;
    if (user.moodle_id) return Number(user.moodle_id) || user.moodle_id;

    const resolvedMoodleUser = await moodleService.resolveMoodleUserForLocalUser(user);
    return resolvedMoodleUser?.id || null;
};

const createLessonValidation = [
    body('title').trim().notEmpty().withMessage('Title is required'),
    body('sort_order').optional().isInt({ min: 0 }).withMessage('Sort order must be a non-negative integer'),
];

const updateLessonValidation = [
    body('title').optional().trim().notEmpty().withMessage('Title cannot be empty'),
    body('sort_order').optional().isInt({ min: 0 }).withMessage('Sort order must be a non-negative integer'),
];

const createLesson = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error: 'Validation failed', details: errors.array() });
        }

        return res.status(400).json({
            error: 'Lesson creation is managed in Moodle. Please add lessons in Moodle.',
        });
    } catch (error) {
        next(error);
    }
};

const listLessons = async (req, res, next) => {
    try {
        const { courseId } = req.params;

        if (!isMoodleCourseId(courseId)) {
            return res.status(404).json({ error: 'Course not found in Moodle.' });
        }

        const moodleCourse = await moodleService.getCourseById(Number(courseId));
        if (!moodleCourse) {
            return res.status(404).json({ error: 'Course not found.' });
        }

        if (req.user.role !== 'admin') {
            const moodleUserId = await resolveMoodleUserId(req.user);
            if (!moodleUserId) {
                return res.status(403).json({
                    error: 'You must sign in with a Moodle-linked account to access lessons.',
                });
            }
        }

        const sections = await moodleService.getCourseContents(Number(courseId));

        const lessons = [];
        let globalSortOrder = 1;

        const isContentModule = (module) => {
            const modname = (module?.modname || '').toLowerCase();
            return modname !== 'label' && modname !== '';
        };

        sections.forEach((section) => {
            const modules = Array.isArray(section?.modules) ? section.modules : [];
            modules
                .filter(isContentModule)
                .forEach((module) => {
                    lessons.push(mapMoodleModuleToLesson({
                        courseId: Number(courseId),
                        module,
                        courseTitle: moodleCourse.displayname || moodleCourse.fullname || 'Moodle Course',
                        sortOrder: globalSortOrder++,
                        sectionName: section.name || null,
                        sectionId: section.id || null,
                    }));
                });
        });

        return res.json({ lessons });
    } catch (error) {
        next(error);
    }
};

const getLesson = async (req, res, next) => {
    try {
        const parsedMoodleLesson = parseMoodleLessonId(req.params.id);

        if (!parsedMoodleLesson) {
            return res.status(404).json({ error: 'Lesson not found in Moodle.' });
        }

        const { courseId, moduleId } = parsedMoodleLesson;
        const moodleCourse = await moodleService.getCourseById(courseId);
        if (!moodleCourse) {
            return res.status(404).json({ error: 'Course not found.' });
        }

        if (req.user.role !== 'admin') {
            const moodleUserId = await resolveMoodleUserId(req.user);
            if (!moodleUserId) {
                return res.status(403).json({
                    error: 'You must sign in with a Moodle-linked account to access lessons.',
                });
            }
        }

        const sections = await moodleService.getCourseContents(courseId);

        let targetModule = null;
        let targetSection = null;
        let globalSortOrder = 1;
        let moduleGlobalIndex = 0;

        for (const section of sections) {
            const modules = Array.isArray(section?.modules) ? section.modules : [];
            for (const module of modules) {
                if (Number(module?.id) === moduleId) {
                    targetModule = module;
                    targetSection = section;
                    moduleGlobalIndex = globalSortOrder;
                    break;
                }
                globalSortOrder++;
            }
            if (targetModule) break;
        }

        if (!targetModule) {
            return res.status(404).json({ error: 'Lesson not found.' });
        }

        const lesson = mapMoodleModuleToLesson({
            courseId,
            module: targetModule,
            courseTitle: moodleCourse.displayname || moodleCourse.fullname || 'Moodle Course',
            sortOrder: moduleGlobalIndex,
            sectionName: targetSection?.name || null,
            sectionId: targetSection?.id || null,
        });

        return res.json({ lesson });
    } catch (error) {
        next(error);
    }
};

const updateLesson = async (req, res, next) => {
    try {
        const errors = validationResult(req);
        if (!errors.isEmpty()) {
            return res.status(400).json({ error: 'Validation failed', details: errors.array() });
        }

        return res.status(400).json({
            error: 'Lesson updates are managed in Moodle. Please edit lessons in Moodle.',
        });
    } catch (error) {
        next(error);
    }
};

const deleteLesson = async (_req, res) => {
    return res.status(400).json({
        error: 'Lesson deletion is managed in Moodle. Please delete lessons in Moodle.',
    });
};

module.exports = {
    upload,
    createLesson,
    listLessons,
    getLesson,
    updateLesson,
    deleteLesson,
    createLessonValidation,
    updateLessonValidation,
};
