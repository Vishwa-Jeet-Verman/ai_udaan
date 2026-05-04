const express = require('express');
const router = express.Router();
const { authenticate } = require('../middleware/authenticate');
const ctrl = require('./calendar.controller');

router.use(authenticate);

router.get('/',        ctrl.getEvents);
router.post('/',       ctrl.createEvent);
router.put('/:id',     ctrl.updateEvent);
router.delete('/:id',  ctrl.deleteEvent);

module.exports = router;
