/**
 * Persistent notification store — saves to notifications.json on disk.
 * Survives server restarts unlike the previous in-memory Map.
 * Keyed by userId (app user id, e.g. 'moodle-95').
 */
const fs = require('fs');
const path = require('path');

const STORE_FILE = path.join(__dirname, 'notifications.json');
const MAX_PER_USER = 100;

// ─── Persistence ─────────────────────────────────────────────────────────────

function loadFromDisk() {
    try {
        if (fs.existsSync(STORE_FILE)) {
            const raw = fs.readFileSync(STORE_FILE, 'utf8');
            const data = JSON.parse(raw);
            return new Map(Object.entries(data || {}));
        }
    } catch (e) {
        console.warn('[NotifStore] Failed to load from disk:', e.message);
    }
    return new Map();
}

let _saveTimer = null;
function scheduleSave() {
    if (_saveTimer) return;
    _saveTimer = setTimeout(() => {
        _saveTimer = null;
        try {
            const obj = Object.fromEntries(_store);
            fs.writeFileSync(STORE_FILE, JSON.stringify(obj, null, 2), 'utf8');
        } catch (e) {
            console.warn('[NotifStore] Failed to save to disk:', e.message);
        }
    }, 500);
}

const _store = loadFromDisk();
console.log(`[NotifStore] Loaded ${_store.size} user notification lists from disk`);

// ─── Helpers ──────────────────────────────────────────────────────────────────

function _userNotifs(userId) {
    if (!_store.has(userId)) _store.set(userId, []);
    return _store.get(userId);
}

// ─── Public API ───────────────────────────────────────────────────────────────

function add(userId, { type = 'info', title, body, data = {} }) {
    const list = _userNotifs(userId);

    // Deduplicate enrollment notifications — one per course per user
    if (type === 'enrollment' && data?.courseId) {
        const exists = list.some(
            n => n.type === 'enrollment' && n.data?.courseId === String(data.courseId)
        );
        if (exists) return list[0]; // already have one for this course
    }

    const notif = {
        id: `local-${Date.now()}-${Math.random().toString(36).slice(2, 6)}`,
        type,
        title,
        body: body || '',
        data,
        read: false,
        createdAt: new Date().toISOString(),
        source: 'local',
    };
    list.unshift(notif);
    _store.set(userId, list.slice(0, MAX_PER_USER));
    scheduleSave();
    return notif;
}

function getAll(userId) {
    return _userNotifs(userId);
}

function markRead(userId, notifId) {
    const notif = _userNotifs(userId).find((n) => n.id === notifId);
    if (notif) {
        notif.read = true;
        scheduleSave();
    }
}

function markAllRead(userId) {
    _userNotifs(userId).forEach((n) => { n.read = true; });
    scheduleSave();
}

module.exports = { add, getAll, markRead, markAllRead };
