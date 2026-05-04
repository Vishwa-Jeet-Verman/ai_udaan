const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authenticate');
const { getDownloads } = require('./download.controller');

router.get('/downloads', authenticate, getDownloads);

module.exports = router;
