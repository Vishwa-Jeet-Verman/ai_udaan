const store = require('./message.store');
const moodleService = require('../services/moodle.service');
const moodleMsgService = require('../services/moodle.message.service');
const moodleLoginService = require('../services/moodle.login.service');

// ─── Constants ────────────────────────────────────────────────────────────────

const ADMIN_MOODLE_ID = Number(process.env.MOODLE_ADMIN_ID || 2);
const ADMIN_APP_ID = `moodle-${ADMIN_MOODLE_ID}`;

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Extract numeric Moodle ID from JWT user object.
 * JWT id is "moodle-{id}", moodle_id is the raw number.
 */
const getMoodleId = (user) => user?.moodle_id || user?.moodleId || null;

/** Returns true if a message content looks like a "New Lesson Added" system notification */
const isNewLessonMsg = (content) => {
    const lower = String(content || '').toLowerCase();
    return lower.includes('new lesson added') || lower.includes('was added to');
};

// ─── Private messages ─────────────────────────────────────────────────────────

exports.getPrivateMessages = async (req, res, next) => {
    try {
        const myMoodleId = getMoodleId(req.user);
        const { partnerId } = req.params;
        const userToken = req.user?.moodle_token;
        
        if (!userToken) {
            return res.status(401).json({ error: 'Moodle token not available. Please re-login.' });
        }

        console.log(`[Messages] 🔑 Using user's Moodle token`);

        let partnerMoodleId;
        if (partnerId === 'admin') {
            partnerMoodleId = ADMIN_MOODLE_ID;
        } else if (partnerId.startsWith('moodle-')) {
            partnerMoodleId = Number(partnerId.replace('moodle-', ''));
        } else {
            partnerMoodleId = Number(partnerId);
        }

        // If sender or recipient invalid, return empty
        if (!myMoodleId || !partnerMoodleId) {
            return res.json({ data: [] });
        }

        // Fetch only from Moodle API using user token
        try {
            console.log(`[Messages] Fetching messages for conversation: ${myMoodleId} ↔ ${partnerMoodleId} using user token`);
            const moodleMessages = await moodleMsgService.getMessagesBetween(myMoodleId, partnerMoodleId, 200, userToken);
            console.log(`[Messages] ✅ getMessagesBetween returned ${moodleMessages.length} messages`);

            // Normalize messages
            const normalized = moodleMessages.map(m => 
                moodleMsgService.normalizeMoodleMessage(m, myMoodleId)
            );

            if (normalized.length > 0) {
                const first = normalized[0];
                const last = normalized[normalized.length - 1];
                console.log(`[Messages] Message timeline:`);
                console.log(`           First: ${first.senderId} → ${first.recipientId} at ${first.timestamp}`);
                console.log(`           Last:  ${last.senderId} → ${last.recipientId} at ${last.timestamp}`);
            }

            // Disable caching for message endpoints — always fetch fresh data
            res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
            res.set('Pragma', 'no-cache');
            res.set('Expires', '0');
            
            return res.json({ data: normalized, source: 'moodle' });
        } catch (err) {
            console.error(`❌ Moodle fetch failed for user ${myMoodleId} ↔ ${partnerMoodleId}:`, err.message);
            res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
            res.set('Pragma', 'no-cache');
            res.set('Expires', '0');
            
            return res.status(500).json({ 
                error: 'Failed to fetch messages from Moodle',
                message: err.message 
            });
        }
    } catch (err) {
        console.error('❌ Error fetching messages:', err.message);
        res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
        res.set('Pragma', 'no-cache');
        res.set('Expires', '0');
        
        return res.status(500).json({ 
            error: 'Failed to fetch messages',
            message: err.message 
        });
    }
};

// Mark all messages in conversation as read when user fetches them
exports.markConversationRead = async (req, res) => {
    try {
        const { partnerId } = req.params;
        const myMoodleId = getMoodleId(req.user);
        const userToken = req.user?.moodle_token;
        
        if (!userToken) {
            return res.status(401).json({ error: 'Moodle token not available. Please re-login.' });
        }

        // Get partner's Moodle ID
        let partnerMoodleId;
        if (partnerId === 'admin') {
            partnerMoodleId = ADMIN_MOODLE_ID;
        } else if (partnerId.startsWith('moodle-')) {
            partnerMoodleId = Number(partnerId.replace('moodle-', ''));
        } else {
            partnerMoodleId = Number(partnerId);
        }
        
        // Mark as read in Moodle API using user token
        if (myMoodleId && partnerMoodleId) {
            moodleMsgService.markMessagesRead(myMoodleId, partnerMoodleId, userToken).catch(err => {
                console.warn('[Messages] Failed to mark messages read:', err.message);
            });
        }
        
        res.json({ message: 'Conversation marked as read.' });
    } catch (err) {
        console.error('[Messages] markConversationRead error:', err.message);
        res.status(500).json({ error: 'Failed to mark conversation as read' });
    }
};

exports.sendPrivateMessage = async (req, res, next) => {
    try {
        const { content, recipientId } = req.body;
        
        if (!content?.trim()) {
            return res.status(400).json({ error: 'Content is required.' });
        }
        if (!recipientId) {
            return res.status(400).json({ error: 'Recipient ID is required.' });
        }

        // Get sender info from authenticated user
        const senderMoodleId = getMoodleId(req.user);
        const userToken = req.user?.moodle_token;

        if (!senderMoodleId || isNaN(senderMoodleId)) {
            return res.status(401).json({ error: 'Sender not authenticated.' });
        }

        if (!userToken) {
            return res.status(401).json({ error: 'Moodle token not available. Please re-login.' });
        }

        // Verify token is still valid
        const tokenValid = await moodleLoginService.verifyToken(userToken);
        if (!tokenValid) {
            console.warn(`[Messages] ⚠️ User's Moodle token is invalid or expired`);
            return res.status(401).json({ 
                error: 'Your Moodle session has expired. Please re-login.',
                code: 'TOKEN_EXPIRED'
            });
        }

        console.log(`[Messages] 📋 SENDER INFO:`, {
            'sender_app_id': req.user.id,
            'sender_moodle_id': senderMoodleId,
            'sender_name': req.user.name,
            'has_user_token': !!userToken,
            'recipient_id': recipientId,
        });

        // Resolve recipient Moodle ID
        let recipientMoodleId;
        if (recipientId === 'admin') {
            recipientMoodleId = ADMIN_MOODLE_ID;
        } else if (recipientId.startsWith('moodle-')) {
            recipientMoodleId = Number(recipientId.replace('moodle-', ''));
        } else {
            recipientMoodleId = Number(recipientId);
        }

        if (!recipientMoodleId || isNaN(recipientMoodleId) || recipientMoodleId <= 0) {
            return res.status(400).json({ error: 'Invalid recipient ID.' });
        }

        // Prevent sending message to yourself
        if (senderMoodleId === recipientMoodleId) {
            console.error(`[Messages] ❌ Cannot send message to yourself!`);
            console.error(`   Sender Moodle ID: ${senderMoodleId}`);
            console.error(`   Recipient Moodle ID: ${recipientMoodleId}`);
            return res.status(400).json({ error: 'Cannot send message to yourself.' });
        }

        console.log(`[Messages] 📤 Sending message via user token:`);
        console.log(`           From: ${senderMoodleId} (${req.user.name})`);
        console.log(`           To: ${recipientMoodleId}`);
        console.log(`           Content: "${content.substring(0, 50)}..."`);

        // Send message using user's own token
        try {
            const response = await moodleMsgService.sendMessage(
                senderMoodleId,
                recipientMoodleId,
                content.trim(),
                userToken  // Pass user's personal token
            );

            console.log(`[Messages] ✅ Message sent successfully to Moodle`);
            
            // Emit to Socket.IO for real-time notification (optional - for app consistency)
            const io = req.app.get('io');
            if (io) {
                const normalizedRecipientId = recipientId === 'admin' ? ADMIN_APP_ID : recipientId;
                
                // Emit to sender's room
                io.to(`user:${req.user.id}`).emit('new_message', {
                    id: response?.msgid || Date.now(),
                    type: 'private',
                    senderId: req.user.id,
                    senderName: req.user.name,
                    senderRole: req.user.role,
                    content: content.trim(),
                    timestamp: new Date().toISOString(),
                    recipientId: normalizedRecipientId,
                    source: 'moodle'
                });
                
                console.log(`[Messages] 📨 Emitted to sender`);
                
                // Emit to recipient's room
                let recipientAppId = recipientId;
                if (recipientId === 'admin') {
                    recipientAppId = ADMIN_APP_ID;
                } else if (!recipientId.startsWith('moodle-') && /^\d+$/.test(recipientId)) {
                    recipientAppId = `moodle-${recipientId}`;
                }
                
                io.to(`user:${recipientAppId}`).emit('new_message', {
                    id: response?.msgid || Date.now(),
                    type: 'private',
                    senderId: req.user.id,
                    senderName: req.user.name,
                    senderRole: req.user.role,
                    content: content.trim(),
                    timestamp: new Date().toISOString(),
                    recipientId: recipientAppId,
                    source: 'moodle'
                });
                
                console.log(`[Messages] 📨 Emitted to recipient`);
            }

            res.status(201).json({ 
                data: {
                    id: response?.msgid || Date.now(),
                    type: 'private',
                    senderId: req.user.id,
                    senderName: req.user.name,
                    senderRole: req.user.role,
                    content: content.trim(),
                    timestamp: new Date().toISOString(),
                    recipientId: recipientId === 'admin' ? ADMIN_APP_ID : recipientId,
                    source: 'moodle',
                    moodleMessageId: response?.msgid
                }
            });
        } catch (err) {
            console.error(`[Messages] ❌ Failed to send message to Moodle:`, err.message);
            return res.status(500).json({ 
                error: 'Failed to send message',
                message: err.message 
            });
        }
    } catch (err) {
        next(err);
    }
};

exports.getPrivateConversations = async (req, res, next) => {
    try {
        const myMoodleId = getMoodleId(req.user);
        const userToken = req.user?.moodle_token;

        if (!userToken) {
            return res.status(401).json({ error: 'Moodle token not available. Please re-login.' });
        }

        if (myMoodleId) {
            // Fetch conversations from Moodle using user token
            const moodleConvs = await moodleMsgService.getConversations(myMoodleId, userToken);

            if (moodleConvs.length > 0) {
                const normalized = await Promise.all(
                    moodleConvs.map(c => moodleMsgService.normalizeMoodleConversation(c, myMoodleId))
                );
                // Filter to ONLY show conversations with admin
                const adminConvs = normalized.filter(c => {
                    const partnerId = Number(c.partnerId.replace('moodle-', ''));
                    return partnerId === ADMIN_MOODLE_ID && c.lastMessage;
                });
                res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
                res.set('Pragma', 'no-cache');
                res.set('Expires', '0');
                return res.json({ data: adminConvs, source: 'moodle' });
            }
        }

        // If no conversations found, return empty
        res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
        res.set('Pragma', 'no-cache');
        res.set('Expires', '0');
        res.json({ data: [], source: 'moodle' });
    } catch (err) {
        console.error('[Messages] getPrivateConversations error:', err.message);
        res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
        res.set('Pragma', 'no-cache');
        res.set('Expires', '0');
        res.status(500).json({ error: 'Failed to fetch conversations', message: err.message });
    }
};

// ─── Poll for new messages (used by Flutter to pick up admin replies from Moodle) ─

exports.pollPrivateMessages = async (req, res) => {
    try {
        const myMoodleId = getMoodleId(req.user);
        const userToken = req.user?.moodle_token;
        const { partnerId } = req.params;
        const since = req.query.since ? Number(req.query.since) : 0; // Unix ms timestamp
        
        if (!userToken) {
            return res.status(401).json({ error: 'Moodle token not available. Please re-login.' });
        }

        let partnerMoodleId;
        if (partnerId === 'admin') {
            partnerMoodleId = ADMIN_MOODLE_ID;
        } else if (partnerId.startsWith('moodle-')) {
            partnerMoodleId = Number(partnerId.replace('moodle-', ''));
        } else {
            partnerMoodleId = Number(partnerId);
        }

        if (!myMoodleId || !partnerMoodleId) {
            return res.json({ data: [] });
        }

        const moodleMessages = await moodleMsgService.getMessagesBetween(
            myMoodleId,
            partnerMoodleId,
            50,
            userToken
        );

        const normalized = moodleMessages
            .map(m => moodleMsgService.normalizeMoodleMessage(m, myMoodleId))
            .filter(m => since === 0 || new Date(m.timestamp).getTime() > since)
            .filter(m => !isNewLessonMsg(m.content));

        res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
        res.set('Pragma', 'no-cache');
        res.set('Expires', '0');
        res.json({ data: normalized });
    } catch (err) {
        console.error('[Messages] pollPrivateMessages error:', err.message);
        res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
        res.set('Pragma', 'no-cache');
        res.set('Expires', '0');
        res.json({ data: [] });
    }
};



exports.getStarred = (req, res) => {
    const msgs = store.getStarredMessages(req.user.id);
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
    res.set('Pragma', 'no-cache');
    res.set('Expires', '0');
    res.json({ data: msgs });
};

exports.toggleStar = (req, res) => {
    const { messageId } = req.params;
    const starred = store.toggleStar(messageId, req.user.id);
    res.json({ starred });
};

// ─── Mark read ────────────────────────────────────────────────────────────────

exports.markRead = async (req, res) => {
    const { messageId } = req.params;
    const myMoodleId = getMoodleId(req.user);
    const userToken = req.user?.moodle_token;

    if (!userToken) {
        return res.status(401).json({ error: 'Moodle token not available. Please re-login.' });
    }

    // Mark read in Moodle using user token
    if (myMoodleId && messageId) {
        moodleMsgService.markMessageRead(myMoodleId, messageId, userToken).catch(err => {
            console.warn('[Messages] Failed to mark message read:', err.message);
        });
    }

    res.json({ message: 'Marked as read.' });
};

// ─── Groups (kept for future use) ─────────────────────────────────────────────

exports.createGroup = async (req, res, next) => {
    try {
        const { name, description, moodleCourseId } = req.body;
        if (!name?.trim()) return res.status(400).json({ error: 'Group name is required.' });

        let group = store.createGroup({
            name: name.trim(),
            description,
            createdBy: req.user.id,
            createdByName: req.user.name,
            moodleCourseId: moodleCourseId || null,
        });

        if (moodleCourseId) {
            try {
                const enrolled = await moodleService.getEnrolledUsers(moodleCourseId);
                for (const u of enrolled) {
                    store.addMemberToGroup(group.id, `moodle-${u.id}`);
                }
                group = store.getGroup(group.id);
            } catch (e) {
                console.warn('[Messages] Could not sync Moodle enrollments:', e.message);
            }
        }

        res.status(201).json({ message: 'Group created.', data: group });
    } catch (err) {
        next(err);
    }
};

exports.getGroups = (req, res) => {
    const groups = req.user.role === 'admin'
        ? store.getAllGroups()
        : store.getUserGroups(req.user.id);
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
    res.set('Pragma', 'no-cache');
    res.set('Expires', '0');
    res.json({ data: groups });
};

exports.joinGroup = (req, res) => {
    const group = store.addMemberToGroup(req.params.groupId, req.user.id);
    if (!group) return res.status(404).json({ error: 'Group not found.' });
    res.json({ message: 'Joined group.', data: group });
};

exports.leaveGroup = (req, res) => {
    const group = store.removeMemberFromGroup(req.params.groupId, req.user.id);
    if (!group) return res.status(404).json({ error: 'Group not found.' });
    res.json({ message: 'Left group.', data: group });
};

exports.getGroupMessages = (req, res) => {
    const group = store.getGroup(req.params.groupId);
    if (!group) return res.status(404).json({ error: 'Group not found.' });
    if (!group.members.includes(req.user.id) && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Not a member of this group.' });
    }
    res.set('Cache-Control', 'no-store, no-cache, must-revalidate, proxy-revalidate, private');
    res.set('Pragma', 'no-cache');
    res.set('Expires', '0');
    res.json({ data: store.getGroupMessages(req.params.groupId) });
};

exports.sendGroupMessage = (req, res) => {
    const { content } = req.body;
    if (!content?.trim()) return res.status(400).json({ error: 'Content is required.' });
    const group = store.getGroup(req.params.groupId);
    if (!group) return res.status(404).json({ error: 'Group not found.' });
    if (!group.members.includes(req.user.id) && req.user.role !== 'admin') {
        return res.status(403).json({ error: 'Not a member of this group.' });
    }
    const msg = store.createMessage({
        type: 'group',
        senderId: req.user.id,
        senderName: req.user.name,
        senderRole: req.user.role,
        content: content.trim(),
        groupId: req.params.groupId,
    });
    const io = req.app.get('io');
    if (io) io.to(`group:${req.params.groupId}`).emit('new_message', msg);
    res.status(201).json({ data: msg });
};
