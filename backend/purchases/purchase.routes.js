const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authenticate');
const {
    enrollInCourse,
    listEnrollments,
    checkEnrollment,
    unenroll,
} = require('./purchase.controller');

// Enroll in a course
router.post('/courses/:courseId/enroll', authenticate, enrollInCourse);

// Check enrollment status for current user
router.get('/courses/:courseId/enroll/check', authenticate, checkEnrollment);

// Unenroll from a course (student = themselves; admin can pass ?userId=)
router.delete('/courses/:courseId/enroll', authenticate, unenroll);

// List all enrollments for the authenticated user
router.get('/enrollments', authenticate, listEnrollments);

module.exports = router;
