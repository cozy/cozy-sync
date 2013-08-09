# request = require './node_modules/jugglingdb-cozy-adapter/node_modules/request-json/node_modules/request/index'
# request {
#         method: "POST",
#         uri: "http://localhost:9101/request/alarm/byuri/"
#         json: { key: 'dc16510a6e0347ddcc48f9594019995b.ics' },
#         headers: {
#           authorization: 'Basic MC50b2phb2RlcnUyenoxdHQ5OnRva2Vu',
#           "user-agent": 'some stuff',
#           'x-auth-token': undefined
#         }
#       }, (error, response, body) ->
#         require('eyes').inspect body
#         console.log("RAW", error, body);


# Client = require("./node_modules/jugglingdb-cozy-adapter/node_modules/request-json/main").JsonClient

# client = new Client 'http://localhost:9101/'
# path = "http://localhost:9101/request/alarm/byuri/"
# params = { key: 'dc16510a6e0347ddcc48f9594019995b.ics' }
# client.post "http://localhost:9101/request/alarm/byuri/", params, (error, response, body) ->
#   require('eyes').inspect body
#   console.log("RAW", error, body);


# {Alarm, Event} = require('./models/calendar')

# Event.byURI 'dc16510a6e0347ddcc48f9594019995b.ics', ->
#   console.log arguments

# Alarm.byURI 'dc16510a6e0347ddcc48f9594019995b.ics', ->
#   console.log arguments



CozyCalDAVBackend = require('./backends/caldav')
back = new CozyCalDAVBackend require('./models/calendar')
back.getCalendarObject 'my-calendar', 'dc16510a6e0347ddcc48f9594019995b.ics', ->
   console.log arguments

# jsDAV = require('jsDAV');


# {Stream} = require('stream')
# e = new Stream()

# callback = ->
#     require('eyes').inspect(arguments, 'ARGUMENTS');

# e.on('test', callback.bind(e, null))

# test =
#     a: 'b'
#     b: 'c'
#     body: []

# e.emit('test', test, test.body)