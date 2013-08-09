db = require './db'
time = require 'time'
moment = require 'moment'

{VCalendar, VTodo, VAlarm, VEvent} = require '../lib/ical_helpers'
byURI = (doc) -> emit (doc.caldavuri or doc._id + '.ics'), doc


# ALARM
module.exports.Alarm = Alarm = db.define 'Alarm',
    id:          String
    trigg:       String
    description: String
    caldavuri:   String
    action:      type: String, default: 'DISPLAY'
    related:     type: String, default: null

Alarm.defineRequest 'byURI', byURI, -> console.log 'req created'
Alarm.all = (cb) -> Alarm.request 'byURI', cb
Alarm.byURI = (uri, cb) ->
    # this fail in strange way if we let request handle JSON
    # bug tracked down to Node's EventEmitter in request :
    # the array is lost somehow
    # unable to reproduce outside of the app
    # may be some module is messing with EventEmitter
    #
    # console.log response.body  ===> [{object}]
    # self.emit 'complete', response, response.body
    # self.on 'complete', =>
    #     console arguments
    #     ===> null, {..., body: [{object}]}, {object}
    req = Alarm.request 'byURI', null, cb
    req.body = JSON.stringify key: uri
    req.setHeader 'content-type', 'application/json'

Alarm::toIcal = (timezone) ->
    date = new time.Date @trigg
    date.setTimezone timezone, false
    vtodo = new VTodo date, @id, @description
    vtodo.addAlarm date
    vtodo

Alarm.fromIcal = (valarm) ->
    alarm = new Alarm()
    alarm.description = valarm.fields["SUMMARY"]
    date = valarm.fields["DSTAMP"]
    date = moment(date, "YYYYMMDDTHHmm00")
    triggerDate = new time.Date new Date(date), 'UTC'
    alarm.trigg = triggerDate.toString().slice(0, 24)
    alarm



# EVENT
module.exports.Event = Event = db.define 'Event',
    id:          String
    start:       String
    end:         String
    place:       String
    description: String
    caldavuri:   String
    diff:        Number
    related:     type: String, default: null


Event.defineRequest 'byURI', byURI, -> console.log 'req created'
Event.all = (cb) -> Event.request 'byURI', cb
Event.byURI = (uri, cb) ->
    # See above
    req = Event.request 'byURI', null, cb
    req.body = JSON.stringify key: uri
    req.setHeader 'content-type', 'application/json'

Event::toIcal = (timezone) ->
    startDate = new time.Date @start
    endDate = new time.Date @end
    startDate.setTimezone timezone, false
    endDate.setTimezone timezone, false
    new VEvent startDate, endDate, @id, @description, @place

Event.fromIcal = (vevent) ->
    event = new Event()
    description = vevent.fields["DESCRIPTION"]
    description = vevent.fields["SUMMARY"] unless description?
    event.description = description
    event.place = vevent.fields["LOCATION"]
    startDate = vevent.fields["DTSTART"]
    startDate = moment startDate, "YYYYMMDDTHHmm00"
    startDate = new time.Date new Date(startDate), 'UTC'
    endDate = vevent.fields["DTEND"]
    endDate = moment endDate, "YYYYMMDDTHHmm00"
    endDate = new time.Date new Date(endDate), 'UTC'
    event.start = startDate.toString().slice(0, 24)
    event.end = endDate.toString().slice(0, 24)
    event