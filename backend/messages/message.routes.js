const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authenticate');
const authorize = require('../middleware/authorize');
const ctrl = require('./message.controller');

// All routes require auth
router.use(authenticate);

// ─── Groups ───────────────────────────────────────────────────────────────────
router.get('/groups', ctrl.getGroups);
router.post('/groups', authorize('admin'), ctrl.createGroup);
router.post('/groups/:groupId/join', ctrl.joinGroup);
router.post('/groups/:groupId/leave', ctrl.leaveGroup);
router.get('/groups/:groupId/messages', ctrl.getGroupMessages);
router.post('/groups/:groupId/messages', ctrl.sendGroupMessage);

// ─── Private messages ─────────────────────────────────────────────────────────
router.get('/private/conversations', ctrl.getPrivateConversations);
router.get('/private/:partnerId/poll', ctrl.pollPrivateMessages);
router.get('/private/:partnerId', ctrl.getPrivateMessages);
router.post('/private', ctrl.sendPrivateMessage);

// ─── Starred ──────────────────────────────────────────────────────────────────
router.get('/starred', ctrl.getStarred);
router.post('/starred/:messageId/toggle', ctrl.toggleStar);

// ─── Mark read ────────────────────────────────────────────────────────────────
router.post('/read/:messageId', ctrl.markRead);
router.post('/private/:partnerId/read-all', ctrl.markConversationRead);

module.exports = router;
