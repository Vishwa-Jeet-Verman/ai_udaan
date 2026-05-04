/**
 * Persistent message store — saves to messages.json on disk.
 * This ensures sender identity (real senderId) survives server restarts,
 * which is critical because Moodle always returns useridfrom=admin for all
 * messages (admin token constraint), so we cannot recover sender from Moodle alone.
 */
const { randomUUID } = require('crypto');
const uuidv4 = randomUUID;
const fs = require('fs');
const path = require('path');

const STORE_FILE = path.join(__dirname, 'messages.json');

// ─── Persistence helpers ──────────────────────────────────────────────────────

function loadFromDisk() {
    try {
        if (fs.existsSync(STORE_FILE)) {
            const raw = fs.readFileSync(STORE_FILE, 'utf8');
            const data = JSON.parse(raw);
            return {
                messages: new Map(Object.entries(data.messages || {})),
                groups: new Map(Object.entries(data.groups || {})),
                starredByUser: new Map(
                    Object.entries(data.starredByUser || {}).map(([k, v]) => [k, new Set(v)])
                ),
            };
        }
    } catch (e) {
        console.warn('[MessageStore] Failed to load from disk:', e.message);
    }
    return { messages: new Map(), groups: new Map(), starredByUser: new Map() };
}

let _saveTimer = null;
function scheduleSave() {
    if (_saveTimer) return;
    _saveTimer = setTimeout(() => {
        _saveTimer = null;
        saveToDisk();
    }, 500); // debounce — write at most every 500ms
}

function saveToDisk() {
    try {
        const data = {
            messages: Object.fromEntries(messages),
            groups: Object.fromEntries(groups),
            starredByUser: Object.fromEntries(
                [...starredByUser.entries()].map(([k, v]) => [k, [...v]])
            ),
        };
        fs.writeFileSync(STORE_FILE, JSON.stringify(data, null, 2), 'utf8');
    } catch (e) {
        console.warn('[MessageStore] Failed to save to disk:', e.message);
    }
}

// ─── Load initial state ───────────────────────────────────────────────────────
const { messages, groups, starredByUser } = loadFromDisk();
console.log(`[MessageStore] Loaded ${messages.size} messages from disk`);

// ─── Helpers ──────────────────────────────────────────────────────────────────
const now = () => new Date().toISOString();

// ─── Message CRUD ─────────────────────────────────────────────────────────────

function createMessage({ type, senderId, senderName, senderRole, content, groupId, recipientId }) {
    const msg = {
        id: uuidv4(),
        type,
        senderId,
        senderName,
        senderRole,
        content,
        groupId: groupId || null,
        recipientId: recipientId || null,
        timestamp: now(),
        readBy: [senderId],
    };
    messages.set(msg.id, msg);
    scheduleSave();
    return msg;
}

function getGroupMessages(groupId) {
    return [...messages.values()]
        .filter(m => m.type === 'group' && m.groupId === groupId)
        .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
}

function getPrivateMessages(userId, partnerId) {
    // Normalise partnerId — 'admin' alias should match 'moodle-2' (or ADMIN_MOODLE_ID)
    const ADMIN_APP_ID = `moodle-${Number(process.env.MOODLE_ADMIN_ID || 2)}`;
    const normPartner = partnerId === 'admin' ? ADMIN_APP_ID : partnerId;
    const normUser = userId;

    return [...messages.values()]
        .filter(m =>
            m.type === 'private' &&
            ((m.senderId === normUser && (m.recipientId === normPartner || m.recipientId === partnerId)) ||
             (m.senderId === normPartner && m.recipientId === normUser) ||
             (m.senderId === partnerId && m.recipientId === normUser))
        )
        .sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
}

/**
 * Find a local message by content + approximate timestamp + conversation participants.
 * The senderId/recipientId scope ensures we don't match messages from other conversations.
 */
function findByContentAndTime(content, timestampIso, windowSeconds = 60, senderIdHint = null, recipientIdHint = null) {
    const ts = new Date(timestampIso).getTime();
    const trimmed = content.trim().toLowerCase();
    const ADMIN_APP_ID = `moodle-${Number(process.env.MOODLE_ADMIN_ID || 2)}`;

    for (const msg of messages.values()) {
        if (msg.content.trim().toLowerCase() !== trimmed) continue;
        const diff = Math.abs(new Date(msg.timestamp).getTime() - ts);
        if (diff > windowSeconds * 1000) continue;

        // If we have conversation hints, verify this message belongs to the right conversation
        if (senderIdHint && recipientIdHint) {
            const participants = new Set([msg.senderId, msg.recipientId]);
            const hintParticipants = new Set([senderIdHint, recipientIdHint, ADMIN_APP_ID]);
            // At least one participant must match a hint
            const hasOverlap = [...participants].some(p => hintParticipants.has(p));
            if (!hasOverlap) continue;
        }

        return msg;
    }
    return null;
}

/**
 * Find a local message by content alone within a conversation (no timestamp constraint).
 * Used as fallback when Moodle timecreated differs significantly from local timestamp.
 */
function findByContent(content, senderIdHint = null, recipientIdHint = null) {
    const trimmed = content.trim().toLowerCase();
    const ADMIN_APP_ID = `moodle-${Number(process.env.MOODLE_ADMIN_ID || 2)}`;
    const hintParticipants = new Set([senderIdHint, recipientIdHint, ADMIN_APP_ID].filter(Boolean));

    for (const msg of messages.values()) {
        if (msg.content.trim().toLowerCase() !== trimmed) continue;
        if (hintParticipants.size > 0) {
            const participants = new Set([msg.senderId, msg.recipientId]);
            const hasOverlap = [...participants].some(p => hintParticipants.has(p));
            if (!hasOverlap) continue;
        }
        return msg;
    }
    return null;
}

function getMessageById(messageId) {
    return messages.get(messageId) || null;
}

function getStarredMessages(userId) {
    const starred = starredByUser.get(userId) || new Set();
    return [...messages.values()]
        .filter(m => starred.has(m.id))
        .sort((a, b) => new Date(b.timestamp) - new Date(a.timestamp));
}

function markRead(messageId, userId) {
    const msg = messages.get(messageId);
    if (msg && !msg.readBy.includes(userId)) {
        msg.readBy.push(userId);
        scheduleSave();
    }
}

function toggleStar(messageId, userId) {
    if (!starredByUser.has(userId)) starredByUser.set(userId, new Set());
    const set = starredByUser.get(userId);
    if (set.has(messageId)) {
        set.delete(messageId);
        scheduleSave();
        return false;
    } else {
        set.add(messageId);
        scheduleSave();
        return true;
    }
}

// ─── Group CRUD ───────────────────────────────────────────────────────────────

function createGroup({ name, description, createdBy, createdByName, moodleCourseId }) {
    const group = {
        id: uuidv4(),
        name,
        description: description || '',
        createdBy,
        createdByName,
        moodleCourseId: moodleCourseId || null,
        members: [createdBy],
        createdAt: now(),
    };
    groups.set(group.id, group);
    scheduleSave();
    return group;
}

function getGroup(groupId) {
    return groups.get(groupId) || null;
}

function getAllGroups() {
    return [...groups.values()].sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));
}

function getUserGroups(userId) {
    return [...groups.values()].filter(g => g.members.includes(userId));
}

function addMemberToGroup(groupId, userId) {
    const group = groups.get(groupId);
    if (!group) return null;
    if (!group.members.includes(userId)) group.members.push(userId);
    scheduleSave();
    return group;
}

function removeMemberFromGroup(groupId, userId) {
    const group = groups.get(groupId);
    if (!group) return null;
    group.members = group.members.filter(id => id !== userId);
    scheduleSave();
    return group;
}

// ─── Conversation list helpers ────────────────────────────────────────────────

function getPrivateConversations(userId) {
    const convMap = new Map();
    for (const msg of messages.values()) {
        if (msg.type !== 'private') continue;
        if (msg.senderId !== userId && msg.recipientId !== userId) continue;
        const partnerId = msg.senderId === userId ? msg.recipientId : msg.senderId;
        const existing = convMap.get(partnerId);
        
        // Only count unread messages from the other person (not from me)
        const isUnread = msg.senderId !== userId && !msg.readBy.includes(userId);
        const unreadIncrement = isUnread ? 1 : 0;
        
        if (!existing || new Date(msg.timestamp) > new Date(existing.lastMessage.timestamp)) {
            convMap.set(partnerId, {
                partnerId,
                partnerName: msg.senderId === userId ? msg.recipientId : msg.senderName,
                lastMessage: msg,
                unread: unreadIncrement,
            });
        } else {
            // Add to unread count for this conversation
            existing.unread += unreadIncrement;
        }
    }
    return [...convMap.values()];
}

module.exports = {
    createMessage,
    getGroupMessages,
    getPrivateMessages,
    findByContentAndTime,
    findByContent,
    getMessageById,
    getStarredMessages,
    markRead,
    toggleStar,
    createGroup,
    getGroup,
    getAllGroups,
    getUserGroups,
    addMemberToGroup,
    removeMemberFromGroup,
    getPrivateConversations,
};
