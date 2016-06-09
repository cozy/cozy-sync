"use strict"

Exc = require "cozy-jsdav-fork/lib/shared/exceptions"
SCCS = require "cozy-jsdav-fork/lib/CalDAV/properties/supportedCalendarComponentSet"
CalendarQueryParser = require('cozy-jsdav-fork/lib/CalDAV/calendarQueryParser')
VObject_Reader = require('cozy-jsdav-fork/lib/VObject/reader')
CalDAV_CQValidator = require 'cozy-jsdav-fork/lib/CalDAV/calendarQueryValidator'
WebdavAccount = require '../models/webdavaccount'
Event = require '../models/event'
async = require "async"
axon = require 'axon'
time  = require "time"
{ICalParser, VCalendar, VTimezone, VEvent} = require "cozy-ical"

log = require('printit')
    date: true
    prefix: 'caldav:backend'

module.exports = class CozyCalDAVBackend

    constructor: (@Event, @User) ->

        @getLastCtag (err, ctag) =>
            # we suppose something happened while webdav was down
            @ctag = ctag + 1
            @saveLastCtag @ctag

            onChange = =>
                @ctag = @ctag + 1
                @saveLastCtag @ctag

                # clear cache
                @icalCalendars = undefined


            # keep ctag updated
            socket = axon.socket 'sub-emitter'
            socket.connect 9105
            socket.on 'alarm.*', onChange
            socket.on 'event.*', onChange

    getLastCtag: (callback) ->
        WebdavAccount.first (err, account) ->
            callback err, account?.ctag or 0

    saveLastCtag: (ctag, callback = ->) ->
        WebdavAccount.first (err, account) ->
            return callback err if err or not account
            account.updateAttributes ctag: ctag, ->

    getCalendarsForUser: (principalUri, callback) ->
        # Return cached version if available, or generate it.
        # principalUri is not handled by the cache.

        if @icalCalendars?
            setTimeout => # "setTimeout 0" to reset stack.
                callback null, @icalCalendars
            , 0

        else # no cache version available, generate it.
            Event.calendars (err, calendars) =>
                @icalCalendars = calendars.map (calendarTag) =>
                    calendarData =
                        id: calendarTag.name
                        uri: calendarTag.name
                        principaluri: principalUri
                        "{http://calendarserver.org/ns/}getctag": @ctag
                        "{urn:ietf:params:xml:ns:caldav}supported-calendar-component-set": SCCS.new [ 'VEVENT' ]
                        "{DAV:}displayname": calendarTag.name
                        "{http://apple.com/ns/ical/}calendar-color": calendarTag.color
                    return calendarData
                callback err, @icalCalendars

    createCalendar: (principalUri, url, properties, callback) ->
        callback null, null

    updateCalendar: (calendarId, mutations, callback) ->
        callback null, false

    deleteCalendar: (calendarId, callback) ->
        callback null, null

    _toICal: (obj, timezone) ->
        cal = new VCalendar organization: 'Cozy', title: 'Cozy Calendar'
        cal.add obj.toIcal timezone
        return cal.toString()

    getCalendarObjects: (calendarId, callback) ->
        objects = []
        async.parallel [
            (cb) => @Event.byCalendar calendarId, cb
            (cb) => @User.getTimezone cb
        ], (err, results) =>

            return callback err if err

            [events, timezone] = results

            objects = events.map (obj) =>

                {lastModification} = obj
                if lastModification?
                    lastModification = new Date lastModification
                else
                    lastModification = new Date()

                id:           obj.id
                uri:          obj.caldavuri or "#{obj.id}.ics"
                calendardata: @_toICal obj, timezone
                lastmodified: lastModification.getTime()

            callback null, objects

    _findCalendarObject: (calendarId, objectUri, callback) ->
        @Event.byURI objectUri, (err, results) -> callback err, results[0]

    # take a calendar object from ICalParser, extract VEvent
    _extractCalObject: (calendarobj) =>
        if calendarobj instanceof VEvent
            return calendarobj
        else
            for obj in calendarobj.subComponents
                found = @_extractCalObject obj
                return found if found

            return false

    _parseSingleObjICal: (calendarData, callback) ->
        new ICalParser().parseString calendarData, (err, calendar) =>
            return callback err if err
            callback null, @_extractCalObject calendar

    getCalendarObject: (calendarId, objectUri, callback) ->
        @_findCalendarObject calendarId, objectUri, (err, obj) =>
            return callback err if err
            return callback null, null unless obj

            timezone = @User.timezone

            {lastModification} = obj
            if lastModification?
                lastModification = new Date lastModification
            else
                lastModification = new Date()

            callback null,
                id:           obj.id
                uri:          obj.caldavuri or "#{obj.id}.ics"
                calendardata: @_toICal obj, timezone
                lastmodified: lastModification.getTime()


    createCalendarObject: (calendarId, objectUri, calendarData, callback) =>
        @_parseSingleObjICal calendarData, (err, obj) =>
            return callback err if err

            if obj.name is 'VEVENT'
                event = @Event.fromIcal obj, calendarId
                # on creation, event id must be null, remove the id
                # that may have been imported from ical object
                event.id = null
                event.caldavuri = objectUri
                @Event.create event, (err, event) -> callback err, null
            else
                callback Exc.notImplementedYet()


    updateCalendarObject: (calendarId, objectUri, calendarData, callback) ->
        @_findCalendarObject calendarId, objectUri, (err, oldObj) =>
            return callback err if err

            @_parseSingleObjICal calendarData, (err, newObj) =>
                return callback err if err

                if newObj.name is 'VEVENT' and oldObj instanceof @Event
                    event = @Event.fromIcal(newObj, calendarId).toObject()
                    delete event.id

                    oldObj.updateAttributes event, (err, event) ->
                        callback err, null

                else
                    callback Exc.notImplementedYet()

    deleteCalendarObject: (calendarId, objectUri, callback) ->
        @_findCalendarObject calendarId, objectUri, (err, obj) ->
            return callback err if err
            obj.destroy callback

    calendarQuery: (calendarId, filters, callback) ->
        console.log 'CalendarQuery', calendarId
        console.log 'Filters:'
        log.info filters
        objects = []
        reader = VObject_Reader.new()
        validator = CalDAV_CQValidator.new()
        async.parallel [
            (cb) => @Event.byCalendar calendarId, cb
            (cb) => @User.getTimezone cb
        ], (err, results) =>
            return callback err if err

            [events, timezone] = results
            ical = null
            vobj = null
            jugglingObj = null
            try
                for jugglingObj in events
                    # @TODO convert directly from juggling to VObject
                    ical = @_toICal jugglingObj, timezone
                    vobj = reader.read ical

                    if validator.validate vobj, filters
                        {id, caldavuri, lastModification} = jugglingObj
                        uri = caldavuri or "#{id}.ics"
                        if lastModification?
                            lastModification = new Date lastModification
                        else
                            lastModification = new Date()

                        objects.push
                            id:           id
                            uri:          uri
                            calendardata: ical
                            lastmodified: lastModification.getTime()

            catch ex
                log.error 'CalendarQuery went wrong with the following' + \
                          'parameters:'
                log.error "calendarId: #{calendarId}"
                log.error "filters:"
                log.error filters
                log.error "exception"
                log.error ex
                log.error "stack"
                log.error ex.stack
                log.error "jugglingObj"
                log.error jugglingObj
                log.error "ical"
                log.error ical
                log.error "vobj"
                console.log vobj
                return callback ex, []

            callback null, objects
