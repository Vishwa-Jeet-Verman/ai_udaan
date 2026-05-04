const moodleService = require('../services/moodle.service');
const notifStore = require('./notification.store');

// ─── Helper: map raw Moodle notification to unified shape ─────────────────────

const mapMoodleNotif = (n) => {
    const component = String(n.component || '').toLowerCase();
    const eventtype  = String(n.eventtype  || '').toLowerCase();
    const subject    = String(n.subject || n.smallmessage || '').toLowerCase();

    let type = 'info';
    if (component.includes('enrol') || eventtype.includes('enrol') || subject.includes('enrol') || subject.includes('welcome'))
        type = 'enrollment';
    else if (component.includes('assign') || eventtype.includes('assign')) type = 'assignment';
    else if (component.includes('grade')  || eventtype.includes('grade'))  type = 'grade';
    else if (component.includes('quiz')   || eventtype.includes('quiz'))   type = 'assignment';
    else if (
        component.includes('resource') || component.includes('url') ||
        component.includes('page') || component.includes('lesson') ||
        eventtype.includes('created') || subject.includes('new') ||
        subject.includes('added') || subject.includes('uploaded')
    ) type = 'new_content';
    else if (component.includes('course') || eventtype.includes('course')) type = 'new_course';

    // Robustly extract courseId from Moodle contexturl
    let courseId = null;
    let cmId     = null;
    const contexturl = n.contexturl || '';
    try {
        // Decode HTML entities first (&amp; → &)
        const decodedUrl = contexturl.replace(/&amp;/g, '&');
        const url      = new URL(decodedUrl);
        const idParam  = url.searchParams.get('id');
        const cidParam = url.searchParams.get('courseid');
        const courseParam = url.searchParams.get('course'); // user/view.php?id=USER&course=COURSE
        const path     = url.pathname.toLowerCase();

        if (cidParam)                        courseId = cidParam;
        else if (courseParam)                courseId = courseParam; // e.g. user/view.php?id=3&course=7
        else if (path.includes('/mod/'))     cmId = idParam;
        else if (path.includes('/course/'))  courseId = idParam;
        else if (idParam)                    courseId = idParam;
    } catch (_) {}

    // Fallback: regex on raw contexturl — look for course= or courseid= first
    if (!courseId && contexturl) {
        const courseMatch = contexturl.match(/[?&]course=(\d+)/i)
            || contexturl.match(/[?&]courseid=(\d+)/i);
        if (courseMatch) courseId = courseMatch[1];
    }
    // Last resort: plain id= (only if path is course-related)
    if (!courseId && contexturl && contexturl.includes('/course/')) {
        const match = contexturl.match(/[?&]id=(\d+)/);
        if (match) courseId = match[1];
    }

    // Fallback: parse [courseId:X] marker from any text field
    if (!courseId) {
        const rawBody = n.fullmessage || n.text || n.smallmessage || '';
        const match   = rawBody.match(/\[courseId:(\d+)\]/);
        if (match) courseId = match[1];
    }

    // Strip the hidden marker from the displayed body
    const cleanBody = (text) =>
        String(text || '').replace(/\[courseId:\d+\]/g, '').trim();

    const createdAt = n.timecreated
        ? new Date(Number(n.timecreated) * 1000).toISOString()
        : new Date().toISOString();

    // Determine read status — inbox messages use 'timeread', popup notifs use 'read'
    const isRead = n.read === true || (n.timeread && n.timeread !== 0);

    // Build display body from available fields
    const rawDisplayBody = n.fullmessagehtml
        ? n.fullmessagehtml.replace(/<[^>]*>/g, ' ').replace(/\s+/g, ' ')
        : (n.fullmessage || n.text || n.smallmessage || '');

    return {
        id:    `moodle-${n.id}`,
        type,
        title: n.subject || n.smallmessage || 'Notification',
        body:  cleanBody(rawDisplayBody),
        data:  { courseId, cmId, moodleNotifId: String(n.id), contexturl },
        read:  !!isRead,
        createdAt,
        source: 'moodle',
    };
};

// ─── GET /api/notifications ───────────────────────────────────────────────────

exports.getNotifications = async (req, res) => {
    const moodleId  = req.user.moodle_id;
    const userToken = req.user.moodle_token || process.env.MOODLE_TOKEN;

    // Always include local store notifications (enrollment, etc.)
    const localNotifs = notifStore.getAll(req.user.id);

    if (!moodleId) {
        const unreadCount = localNotifs.filter((n) => !n.read).length;
        return res.json({ notifications: localNotifs, unreadCount });
    }

    try {
        const raw = await moodleService.getMoodleNotifications(moodleId, userToken);
        const moodleNotifs = raw.map(mapMoodleNotif);

        // Merge: local first (newest), then Moodle — deduplicate by title+date proximity
        const merged = [...localNotifs];
        for (const mn of moodleNotifs) {
            const isDup = localNotifs.some(
                (ln) =>
                    ln.title === mn.title &&
                    Math.abs(new Date(ln.createdAt) - new Date(mn.createdAt)) < 60000
            );
            if (!isDup) merged.push(mn);
        }

        // Sort newest first
        merged.sort((a, b) => new Date(b.createdAt) - new Date(a.createdAt));

        const unreadCount = merged.filter((n) => !n.read).length;
        return res.json({ notifications: merged, unreadCount });
    } catch (err) {
        console.error('[Notifications] getNotifications error:', err.message);
        const unreadCount = localNotifs.filter((n) => !n.read).length;
        return res.json({ notifications: localNotifs, unreadCount });
    }
};

// ─── PATCH /api/notifications/:id/read ───────────────────────────────────────

exports.markRead = async (req, res) => {
    const { id }    = req.params;
    const userToken = req.user.moodle_token || process.env.MOODLE_TOKEN;

    if (id.startsWith('local-')) {
        notifStore.markRead(req.user.id, id);
        return res.json({ success: true });
    }

    if (!id.startsWith('moodle-')) {
        return res.json({ success: true });
    }

    const moodleNotifId = id.replace('moodle-', '');
    if (userToken) {
        await moodleService.markMoodleNotificationRead(moodleNotifId, userToken);
    }
    return res.json({ success: true });
};

// ─── PATCH /api/notifications/read-all ───────────────────────────────────────

exports.markAllRead = async (req, res) => {
    const moodleId  = req.user.moodle_id;
    const userToken = req.user.moodle_token || process.env.MOODLE_TOKEN;

    notifStore.markAllRead(req.user.id);

    if (moodleId && userToken) {
        await moodleService.markAllMoodleNotificationsRead(moodleId, userToken);
    }
    return res.json({ success: true });
};
