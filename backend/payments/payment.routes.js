const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authenticate');
const { createOrder, verifyPayment } = require('./payment.controller');

// Create Razorpay order for course enrollment
router.post('/courses/:courseId/order', authenticate, createOrder);

// Verify payment and enroll user
router.post('/courses/:courseId/verify', authenticate, verifyPayment);

module.exports = router;
