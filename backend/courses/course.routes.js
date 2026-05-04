const express = require('express');
const router = express.Router();
const { authenticate, optionalAuth } = require('../middleware/authenticate');
const authorize = require('../middleware/authorize');
const {
    createCourse,
    listCourses,
    getCourse,
    listMyCourses,
    updateCourse,
    deleteCourse,
    courseValidation,
} = require('./course.controller');

router.get('/', listCourses);
router.get('/my', authenticate, listMyCourses);
router.get('/:id', optionalAuth, getCourse);
router.post('/', authenticate, authorize('admin'), courseValidation, createCourse);
router.put('/:id', authenticate, authorize('admin'), courseValidation, updateCourse);
router.delete('/:id', authenticate, authorize('admin'), deleteCourse);

module.exports = router;
