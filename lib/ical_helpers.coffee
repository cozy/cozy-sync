fs = require 'fs'
moment = require 'moment'
lazy = require 'lazy'

# Small module to generate iCal file from JS Objects or to parse iCal file
# to obtain explicit JS Objects.
#
# This module is inpired by the icalendar Python module.


# Buffer manager to easily build long string.
class iCalBuffer
    # Make this buffer streamablE

    txt: ''

    addString: (text) ->
        @txt += text

    addStrings: (texts) ->
        @addString text for text in texts

    addLine: (text) ->
        @addString "#{text}\r\n"

    addLines: (texts) ->
        @addLine text for text in texts

    toString: -> @txt


# Base ICal Component. This class is aimed to be extended not to be used
# directly.
module.exports.VComponent = class VComponent
    name: 'VCOMPONENT'

    constructor: ->
        @subComponents = []
        @fields = {}

    toString: ->
        buf = new iCalBuffer
        buf.addLine "BEGIN:#{@name}"
        buf.addLine "#{att}:#{val}" for att, val of @fields
        buf.addLine component.toString() for component in @subComponents
        buf.addString "END:#{@name}"

    formatIcalDate: (date) ->
        moment(date).format('YYYYMMDDTHHmm00')

    add: (component) ->
        @subComponents.push component


# Calendar component. It's the representation of the root object of a Calendar.
module.exports.VCalendar = class VCalendar extends VComponent
    name: 'VCALENDAR'

    constructor: (organization, title) ->
        super
        @fields =
            VERSION: "2.0"

        @fields['PRODID'] = "-//#{organization}//NONSGML #{title}//EN"


# An alarm is there to warn the calendar owner of something. It could be
# included in an event or in a todo.
module.exports.VAlarm = class VAlarm extends VComponent
    name: 'VALARM'

    constructor: (date) ->
        super
        @fields =
            ACTION: 'DISPLAY'
            REPEAT: '1'
            TRIGGER: @formatIcalDate date


# The VTodo is used to described a dated action.
module.exports.VTodo = class VTodo extends VComponent
    name: 'VTODO'

    constructor: (date, id, description) ->
        super
        @fields =
            DSTAMP: @formatIcalDate date
            SUMMARY: description
            UID: id

    addAlarm: (date) ->
        @add new VAlarm date

# Additional components not supported yet by Cozy Cloud.
module.exports.VEvent = class VEvent extends VComponent
    name: 'VEVENT'

    constructor: (startDate, endDate, id, description, location) ->
        super
        @fields =
            DESCRIPTION: description
            DTSTART: @formatIcalDate startDate
            DTEND: @formatIcalDate endDate
            LOCATION: location
            UID: id

module.exports.VTimezone = class VTimezone extends VComponent
    name: 'VTIMEZONE'
module.exports.VJournal = class VJournal extends VComponent
    name: 'VJOURNAL'
module.exports.VFreeBusy = class VFreeBusy extends VComponent
    name: 'VFREEBUSY'
module.exports.VStandard = class VStandard extends VComponent
    name: 'VSTANDARD'
module.exports.VDaylight = class VDaylight extends VComponent
    name: 'VDAYLIGHT'

module.exports.ICalParser = class ICalParser

    @components:
        VTODO: VTodo
        VALARM: VAlarm
        VEVENT: VEvent
        VJOURNAL: VJournal
        VFREEBUSY: VFreeBusy
        VTIMEZONE: VTimezone
        STANDARD: VStandard
        DAYLIGHT: VDaylight

    parseFile: (file, callback) ->
        @parse fs.createReadStream(file), callback

    parseString: (string, callback) ->
        class FakeStream extends require('events').EventEmitter
            readable: true
            writable: false
            setEncoding: -> throw 'not implemented'
            pipe: -> throw 'not implemented'
            destroy: ->  # nothing to do
            resume: ->   # nothing to do
            pause: ->    # nothing to do
            send: (string) ->
                @emit 'data', string
                @emit 'end'

        fakeStream = new FakeStream
        @parse fakeStream, callback
        fakeStream.send string


    parse: (stream, callback) ->
        result = {}
        noerror = true
        lineNumber = 0
        component = null
        parent = null

        stream.on 'end', ->
            callback null, result if noerror

        sendError = (msg) ->
            callback new Error "#{msg} (line #{lineNumber})" if noerror
            noerror = false
            # TODO find a way to stop the stream

        createComponent = (name) ->
            parent = component

            console.log "CC", name

            if name is "VCALENDAR"
                if result.fields?
                    sendError "Cannot import more than one calendar"
                component = new VCalendar()
                result = component

            else if name in Object.keys(ICalParser.components)
                component = new ICalParser.components[name]()

            else
                sendError "Malformed ical file"

            component?.parent = parent
            parent?.add component

        lineParser = (line) ->
            lineNumber++

            line = line.toString('utf-8').trim()
            tuple = line.split(':')

            if tuple.length < 2
                sendError "Malformed ical file"
            else
                key = tuple[0]
                tuple.shift()
                value = tuple.join('')

                if key is "BEGIN"
                    createComponent value
                else if key is "END"
                    component = component.parent
                else if not (component? or result?)
                    sendError "Malformed ical file"
                else if key? and key isnt '' and component?
                    key = key.split(';')[0]
                    component.fields[key] = value
                else
                    sendError "Malformed ical file"

        lazy(stream).lines.forEach lineParser
