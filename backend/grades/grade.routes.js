const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authenticate');
const { getGrades } = require('./grade.controller');

router.get('/grades', authenticate, getGrades);

module.exports = router;
