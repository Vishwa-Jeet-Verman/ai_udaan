const moodleService = require('../services/moodle.service');

// Mimetypes we expose as downloadable files
const DOWNLOADABLE_MIMETYPES = [
    'application/pdf',
    'application/msword',
    'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'application/vnd.ms-powerpoint',
    'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'application/vnd.ms-excel',
    'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'application/zip',
    'application/x-zip-compressed',
    'text/plain',
    'image/jpeg',
    'image/png',
    'image/gif',
    'image/webp',
];

const DOWNLOADABLE_EXTENSIONS = [
    '.pdf', '.doc', '.docx', '.ppt', '.pptx',
    '.xls', '.xlsx', '.zip', '.txt', '.jpg',
    '.jpeg', '.png', '.gif', '.webp',
];

function isDownloadable(filename, mimetype) {
    const ext = (filename || '').toLowerCase().slice(filename.lastIndexOf('.'));
    const mime = (mimetype || '').toLowerCase();
    return (
        DOWNLOADABLE_MIMETYPES.some(m => mime.startsWith(m)) ||
        DOWNLOADABLE_EXTENSIONS.includes(ext)
    );
}

function formatFileSize(bytes) {
    if (!bytes || bytes === 0) return '0 B';
    const k = 1024;
    const sizes = ['B', 'KB', 'MB', 'GB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));
    return `${parseFloat((bytes / Math.pow(k, i)).toFixed(1))} ${sizes[i]}`;
}

const getDownloads = async (req, res, next) => {
    try {
        const moodleUserId = req.user?.moodle_id;
        if (!moodleUserId) {
            return res.status(403).json({ error: 'Moodle account required to access downloads.' });
        }

        // Fetch user's enrolled courses
        const enrolledCourses = await moodleService.getUserCourses(moodleUserId);
        if (!enrolledCourses.length) {
            return res.json({ downloads: [] });
        }

        const downloads = [];

        for (const course of enrolledCourses) {
            const courseId = course.id;
            const courseTitle = course.displayname || course.fullname || `Course ${courseId}`;

            let sections = [];
            try {
                sections = await moodleService.getCourseContents(courseId);
            } catch (_) {
                continue;
            }

            for (const section of sections) {
                const modules = Array.isArray(section?.modules) ? section.modules : [];
                for (const module of modules) {
                    const contents = Array.isArray(module?.contents) ? module.contents : [];
                    for (const file of contents) {
                        if (!file?.fileurl || !file?.filename) continue;
                        if (!isDownloadable(file.filename, file.mimetype)) continue;

                        downloads.push({
                            id: `${courseId}-${module.id}-${encodeURIComponent(file.filename)}`,
                            courseId: String(courseId),
                            courseTitle,
                            sectionName: section.name || null,
                            moduleName: module.name || file.filename,
                            filename: file.filename,
                            fileurl: moodleService.appendTokenToUrl(file.fileurl),
                            mimetype: file.mimetype || 'application/octet-stream',
                            filesize: file.filesize || 0,
                            filesizeFormatted: formatFileSize(file.filesize),
                            timemodified: file.timemodified
                                ? new Date(file.timemodified * 1000).toISOString()
                                : null,
                        });
                    }
                }
            }
        }

        // Sort by most recently modified
        downloads.sort((a, b) => {
            if (!a.timemodified) return 1;
            if (!b.timemodified) return -1;
            return new Date(b.timemodified) - new Date(a.timemodified);
        });

        return res.json({ downloads });
    } catch (error) {
        next(error);
    }
};

module.exports = { getDownloads };
