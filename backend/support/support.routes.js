const express = require('express');
const { authenticate } = require('../middleware/authenticate');
const SupportController = require('./support.controller');

const router = express.Router();

// Send support/feedback email
router.post('/send', authenticate, SupportController.sendSupportEmail);

module.exports = router;
