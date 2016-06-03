cozydb = require 'cozydb'
time = require 'time'
moment = require 'moment'
async = require 'async'
{VCalendar, VTodo, VAlarm, VEvent} = require '../lib/ical_helpers'
Tag = require '../models/tag'

# EVENT
module.exports = Event = cozydb.getModel 'Event',
    id: type:String, default: null
    caldavuri: String
    start: String
    end: String
    place: type: String, default: ''
    details: type: String, default: ''
    description: type: String, default: ''
    rrule: String
    attendees   : type : [Object]
    related: type: String, default: null
    timezone    : type : String
    alarms      : type : [Object]
    tags : type : (x) -> x
    created     : type: String
    lastModification: type: String
    mozLastack : type: String # Lightning saves here when he display reminders.
    uid: String

# Add Ical utilities to Event model
require('cozy-ical').decorateEvent Event

# 'start' and 'end' use those format,
# According to allDay or rrules.
Event.dateFormat = 'YYYY-MM-DD'
Event.ambiguousDTFormat = 'YYYY-MM-DD[T]HH:mm:00.000'
Event.utcDTFormat = 'YYYY-MM-DD[T]HH:mm:00.000[Z]'

# Handle only unique units strings.
Event.alarmTriggRegex = /(\+?|-)PT?(\d+)(W|D|H|M|S)/

Event.all = (cb) -> Event.request 'byURI', cb

Event.byCalendar = (calendarId, callback) ->
    Event.request 'byCalendar', key: calendarId, callback

Event.tags = (callback) ->
    Event.rawRequest "tags", group: true, (err, results) ->
        return callback err if err
        out = calendar: [], tag: []
        for result in results
            [type, tag] = result.key
            out[type].push tag
        callback null, out

Event.calendars = (callback) ->
    Event.tags (err, results) ->
        return callback err, [] if err
        async.map results.calendar, Tag.getOrCreateByName, callback

Event.byURI = (uri, cb) ->
    # See Alarm
    Event.request 'byURI', key: uri, cb
