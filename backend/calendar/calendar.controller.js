const moodleService = require('../services/moodle.service');

// ─── Helper: map Moodle event to unified shape ────────────────────────────────
const mapEvent = (e) => ({
    id: String(e.id),
    name: e.name || '',
    description: e.description || '',
    timestart: e.timestart,
    timeduration: e.timeduration || 0,
    eventtype: e.eventtype || 'user',
    courseid: e.courseid ? String(e.courseid) : null,
    userid: e.userid ? String(e.userid) : null,
    visible: e.visible !== 0,
    // ISO string for Flutter
    startAt: new Date(e.timestart * 1000).toISOString(),
    endAt: e.timeduration
        ? new Date((e.timestart + e.timeduration) * 1000).toISOString()
        : null,
});

// ─── GET /api/calendar/events ─────────────────────────────────────────────────
exports.getEvents = async (req, res, next) => {
    try {
        const { moodle_id, moodle_token } = req.user;
        if (!moodle_id || !moodle_token) {
            return res.status(400).json({ error: 'Moodle credentials missing' });
        }

        // Optional date range filters (Unix timestamps)
        const timestart = req.query.timestart ? Number(req.query.timestart) : Math.floor(Date.now() / 1000) - 30 * 86400;
        const timeend   = req.query.timeend   ? Number(req.query.timeend)   : Math.floor(Date.now() / 1000) + 90 * 86400;

        const result = await moodleService.makeRequest(
            'core_calendar_get_calendar_events',
            {
                'options[userevents]': 1,
                'options[siteevents]': 1,
                'options[timestart]': timestart,
                'options[timeend]': timeend,
            },
            moodle_token
        );

        const events = Array.isArray(result?.events) ? result.events : [];
        res.json({ events: events.map(mapEvent) });
    } catch (err) {
        next(err);
    }
};

// ─── POST /api/calendar/events ────────────────────────────────────────────────
exports.createEvent = async (req, res, next) => {
    try {
        const { moodle_id, moodle_token } = req.user;
        if (!moodle_id || !moodle_token) {
            return res.status(400).json({ error: 'Moodle credentials missing' });
        }

        const { name, description = '', timestart, timeduration = 0, eventtype = 'user', courseid } = req.body;

        if (!name || !timestart) {
            return res.status(400).json({ error: 'name and timestart are required' });
        }

        const params = {
            'events[0][name]':        name,
            'events[0][description]': description,
            'events[0][format]':      1,
            'events[0][timestart]':   Number(timestart),
            'events[0][timeduration]': Number(timeduration),
            'events[0][eventtype]':   eventtype,
            'events[0][repeats]':     0,
        };

        if (courseid) params['events[0][courseid]'] = Number(courseid);

        const result = await moodleService.makeRequest(
            'core_calendar_create_calendar_events',
            params,
            moodle_token
        );

        const created = Array.isArray(result?.events) ? result.events[0] : null;
        if (!created) return res.status(500).json({ error: 'Event creation failed' });

        res.status(201).json({ event: mapEvent(created) });
    } catch (err) {
        next(err);
    }
};

// ─── PUT /api/calendar/events/:id ─────────────────────────────────────────────
exports.updateEvent = async (req, res, next) => {
    try {
        const { moodle_token } = req.user;
        const { id } = req.params;
        const { name, description, timestart, timeduration } = req.body;

        const params = { 'events[0][id]': Number(id) };
        if (name        !== undefined) params['events[0][name]']         = name;
        if (description !== undefined) params['events[0][description]']  = description;
        if (timestart   !== undefined) params['events[0][timestart]']    = Number(timestart);
        if (timeduration !== undefined) params['events[0][timeduration]'] = Number(timeduration);

        await moodleService.makeRequest(
            'core_calendar_update_calendar_events',
            params,
            moodle_token
        );

        res.json({ success: true });
    } catch (err) {
        next(err);
    }
};

// ─── DELETE /api/calendar/events/:id ─────────────────────────────────────────
exports.deleteEvent = async (req, res, next) => {
    try {
        const { moodle_token } = req.user;
        const { id } = req.params;

        await moodleService.makeRequest(
            'core_calendar_delete_calendar_events',
            { 'events[0][eventid]': Number(id), 'events[0][repeat]': 0 },
            moodle_token
        );

        res.json({ success: true });
    } catch (err) {
        next(err);
    }
};
