helpers = require './helpers'
should = require('chai').Should()
xmldoc = require 'xmldoc'
Contact = require '../server/models/contact'

describe 'Caldav support', ->

    before helpers.cleanDB
    before helpers.startServer
    before -> console.log "Server started"
    before helpers.makeDAVAccount
    before -> console.log "DAV Account created"
    #before helpers.createUser
    before helpers.createEvent 'A', 'B', 13
    before helpers.createEvent 'C', 'D', 15
    before ->
        url = '/public/webdav/calendars/me/my-calendar/'
        @event1Id = @events['A'].id
        @event1href = url + @events['A'].id + '.ics'
        @event2href = url + @events['C'].id + '.ics'

    after helpers.closeServer
    after helpers.cleanDB


    describe 'Apple PROPFIND /public/webdav/calendars/me/my-calendar/ D=1', ->

        before helpers.send 'PROPFIND', '/public/calendars/me/my-calendar/', """
            <?xml version="1.0" encoding="UTF-8"?>
            <A:propfind xmlns:A="DAV:">
              <A:prop>
                <A:getcontenttype/>
                <A:getetag/>
              </A:prop>
            </A:propfind>
        """, depth: 1

        it 'should contains a ref to both events', ->
            body = new xmldoc.XmlDocument @resbody
            responses = body.childrenNamed 'd:response'
            responses.length.should.equal 3 #2events + calendar itself
            hrefs = responses.map (res) -> res.childNamed('d:href').val

            hrefs.should.include @event1href
            hrefs.should.include @event2href



    describe 'Apple REPORT /public/webdav/calendars/me/my-calendar/', ->

        before (done) ->
            helpers.send('REPORT', '/public/calendars/me/my-calendar/', """
                <?xml version="1.0" encoding="UTF-8"?>
                <B:calendar-multiget xmlns:B="urn:ietf:params:xml:ns:caldav">
                  <A:prop xmlns:A="DAV:">
                    <A:getetag/>
                    <B:calendar-data/>
                    <C:updated-by xmlns:C="http://calendarserver.org/ns/"/>
                    <B:schedule-tag/>
                    <C:created-by xmlns:C="http://calendarserver.org/ns/"/>
                  </A:prop>
                  <A:href xmlns:A="DAV:">#{@event1href}</A:href>
                  <A:href xmlns:A="DAV:">#{@event2href}</A:href>
                </B:calendar-multiget>
            """).call(this, done)

        it 'contains event data', ->

            body = new xmldoc.XmlDocument @resbody
            responses = body.childrenNamed 'd:response'

            results = {}
            for res in responses
                href = res.childNamed('d:href')?.val
                propstat = res.childNamed('d:propstat')
                prop = propstat.childNamed('d:prop')
                card = prop.childNamed('cal:calendar-data').val

                results[href] = card

            results[@event1href].should.have.string 'DESCRIPTION:B'
            results[@event2href].should.have.string 'DESCRIPTION:D'

    describe 'Theory CALENDAR QUERY', ->
        before (done) ->
            @timeout 5000
            helpers.send('REPORT', '/public/calendars/me/my-calendar/', """
                <?xml version="1.0" encoding="utf-8" ?>
               <C:calendar-query xmlns:C="urn:ietf:params:xml:ns:caldav">
                 <D:prop xmlns:D="DAV:">
                   <D:getetag/>
                   <C:calendar-data/>
                 </D:prop>
                 <C:filter>
                   <C:comp-filter name="VCALENDAR">
                     <C:comp-filter name="VEVENT">
                       <C:prop-filter name="UID">
                         <C:text-match collation="i;octet">#{@event1Id}</C:text-match>
                       </C:prop-filter>
                     </C:comp-filter>
                   </C:comp-filter>
                 </C:filter>
               </C:calendar-query>
            """, depth: 1).call(this, done)

        it 'responds with 1 event', ->

            console.log @resbody

            body = new xmldoc.XmlDocument @resbody
            responses = body.childrenNamed 'd:response'

            results = {}
            for res in responses
                href = res.childNamed('d:href')?.val
                propstat = res.childNamed('d:propstat')
                prop = propstat.childNamed('d:prop')
                card = prop.childNamed('cal:calendar-data').val

                results[href] = card

            results[@event1href].should.have.string 'DESCRIPTION:B'

