"use strict";

Exc = require "jsDAV/lib/shared/exceptions"
async = require "async"
{ICalParser, VCalendar, VEvent, VTodo} = require "../lib/ical_helpers"

module.exports = class CozyCalDAVBackend

    constructor: (models) ->
        {@Event, @Alarm} = models

    getCalendarsForUser: (principalUri, callback) ->
        calendar =
            id: 'my-calendar'
            uri: 'my-calendar'
            principaluri: principalUri
            "{DAV:}displayname": 'Cozy Calendar'
        callback null, [calendar]

    createCalendar: (principalUri, url, properties, callback) ->
        callback null, null

    updateCalendar: (calendarId, mutations, callback) ->
        callback null, null

    deleteCalendar: (calendarId, callback) ->
        callback null, null

    _toICal: (obj) ->
        cal = new VCalendar('cozy', 'my-calendar')
        cal.add obj.toIcal() #todo : handle timezone
        cal.toString()

    getCalendarObjects: (calendarId, callback) ->
        objects = []
        async.parallel [
            (cb) => @Alarm.all cb
            (cb) => @Event.all cb
        ], (err, results) =>
            return callback err if err

            objects = results[0].concat(results[1]).map (obj) =>
                id:           obj.id
                uri:          obj.caldavuri or (obj.id + '.ics')
                calendardata: @_toICal(obj)
                lastmodified: new Date().getTime()

            console.log "GETCALENDAROBJECTS", objects

            callback null, objects

    _findCalendarObject: (calendarId, objectUri, callback) ->

        async.series [
            (cb) => @Alarm.byURI objectUri, cb
            (cb) => @Event.byURI objectUri, cb
        ], (err, results) =>
            object = (results[0]?[0] or results[1]?[0])
            console.log "GETOBJECT", objectUri, object
            callback err, object

    # take a calendar object from ICalParser, extract VEvent ot VTodo
    _extractCalObject: (calendarobj) =>
        if calendarobj instanceof VEvent or calendarobj instanceof VTodo
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

            return callback null,
                id:           obj.id
                uri:          obj.caldavuri or (obj.id + '.ics')
                calendardata: @_toICal(obj)
                lastmodified: new Date().getTime()


    createCalendarObject: (calendarId, objectUri, calendarData, callback) =>
        @_parseSingleObjICal calendarData, (err, obj) =>
            return callback err if err

            if obj.name is 'VEVENT'
                event = @Event.fromIcal obj
                event.caldavuri = objectUri
                @Event.create event, (err, event) ->
                    callback err, null

            else if obj.name is 'VTODO'
                console.log "ALARM"
                alarm = @Alarm.fromIcal obj
                alarm.caldavuri = objectUri
                @Alarm.create alarm, (err, alarm) ->
                    callback err, null

            else
                callback Exc.notImplementedYet()


    updateCalendarObject: (calendarId, objectUri, calendarData, callback) ->
        @_findCalendarObject calendarId, objectUri, (err, oldObj) =>
            return callback err if err

            @_parseSingleObjICal calendarData, (err, newObj) =>
                return callback err if err

                console.log "UPDATE", newObj.name, oldObj instanceof @Event

                if newObj.name is 'VEVENT' and oldObj instanceof @Event
                    event = @Event.fromIcal newObj
                    oldObj.updateAttributes event, (err, event) ->
                        console.log "RESULT", err, event
                        callback err, null

                else if newObj.name is 'VTODO' and oldObj instanceof @Alarm
                    console.log "ALARM"
                    alarm = @Alarm.fromIcal newObj
                    oldObj.updateAttributes alarm, (err, alarm) ->
                        callback err, null

                else
                    callback Exc.notImplementedYet()

    deleteCalendarObject: (calendarId, objectUri, callback) ->
        @_findCalendarObject calendarId, objectUri, (err, obj) ->
            return callback err if err
            obj.destroy callback

    calendarQuery: (calendarId, filters, callback) ->
        callback Exc.notImplementedYet()
