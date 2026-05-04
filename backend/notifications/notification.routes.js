const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authenticate');
const { getNotifications, markRead, markAllRead } = require('./notification.controller');

router.get('/', authenticate, getNotifications);
router.patch('/read-all', authenticate, markAllRead);
router.patch('/:id/read', authenticate, markRead);

module.exports = router;
