const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authenticate');
const authorize = require('../middleware/authorize');
const {
    upload,
    createLesson,
    listLessons,
    getLesson,
    updateLesson,
    deleteLesson,
    createLessonValidation,
    updateLessonValidation,
} = require('./lesson.controller');

// Student / admin — read
router.get('/courses/:courseId/lessons', authenticate, listLessons);
router.get('/lessons/:id', authenticate, getLesson);

// Admin — write
router.post(
    '/courses/:courseId/lessons',
    authenticate,
    authorize('admin'),
    upload.single('file'),
    createLessonValidation,
    createLesson
);
router.put(
    '/lessons/:id',
    authenticate,
    authorize('admin'),
    upload.single('file'),
    updateLessonValidation,
    updateLesson
);
router.delete('/lessons/:id', authenticate, authorize('admin'), deleteLesson);

module.exports = router;
