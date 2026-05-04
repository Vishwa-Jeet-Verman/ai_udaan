/**
 * Notification service — pushes real-time notifications via Socket.io
 * and persists them in the local store so the panel can show them.
 */
const notifStore = require('./notification.store');

/**
 * Push a notification to a specific user.
 * @param {import('express').Application} app
 * @param {string} userId - App user ID (e.g. 'moodle-95')
 * @param {{ title: string, body: string, type?: string, data?: object }} payload
 */
function push(app, userId, payload) {
    if (!userId) return;

    // Persist in local store so the notification panel can show it
    const notification = notifStore.add(userId, {
        type: payload.type || 'info',
        title: payload.title || 'Notification',
        body: payload.body || '',
        data: payload.data || {},
    });

    // Also emit real-time via socket if available
    const io = app?.get('io');
    if (io) {
        io.to(`user:${userId}`).emit('notification', notification);
    }
}

/**
 * Broadcast a notification to a list of user IDs (e.g. all enrolled students).
 * @param {import('express').Application} app
 * @param {string[]} userIds
 * @param {{ title: string, body: string, type?: string, data?: object }} payload
 */
function pushToMany(app, userIds, payload) {
    if (!Array.isArray(userIds)) return;
    userIds.forEach((uid) => push(app, uid, payload));
}

module.exports = { push, pushToMany };
