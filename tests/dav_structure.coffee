helpers = require './helpers'
should = require('chai').Should()

describe 'Basic DAV Structure', ->

    #before require '../server/models/requests'
    before helpers.cleanDB
    before helpers.startServer
    before helpers.makeDAVAccount
    after  helpers.closeServer
    after  helpers.cleanDB

    describe 'Android PROPFIND /public/webdav/', ->

        before helpers.send 'PROPFIND', '/public', """
            <?xml version="1.0" encoding="utf-8" ?>
            <A:propfind xmlns:A="DAV:">
                <A:prop><A:current-user-principal/></A:prop>
            </A:propfind>
        """, depth: 0

        it 'contains a ref to "me" principals', ->
            ref2me = '<d:current-user-principal><d:href>' +
                     '/public/webdav/principals/me/' +
                     '</d:href></d:current-user-principal>'

            @resbody.should.have.string ref2me


    # describe 'Android PROPFIND /public/webdav/principals/me/', ->

    #     before helpers.send 'PROFIND', '/public/principals/me', """
    #         <?xml version="1.0" encoding="utf-8" ?>
    #         <A:propfind xmlns:B="urn:ietf:params:xml:ns:carddav" xmlns:A="DAV:">
    #             <A:prop><B:addressbook-home-set/></A:prop>
    #         </A:propfind>
    #     """, depth: 0

    #     it 'contains a ref to the addressbook set', ->
    #         ref = '<card:addressbook-home-set><d:href>' +
    #               '/public/webdav/addressbooks/me/' +
    #               '</d:href></card:addressbook-home-set>'
    #         @resbody.should.have.string ref

    # describe 'Apple PROPFIND /public/webdav/principals/me/', ->

    #     before helpers.send 'PROFIND', '/public/principals/me', """
    #        <?xml version="1.0" encoding="UTF-8"?>
    #        <A:propfind xmlns:A="DAV:">
    #        <A:prop>
    #           <B:addressbook-home-set xmlns:B="urn:ietf:params:xml:ns:carddav"/>
    #           <B:directory-gateway xmlns:B="urn:ietf:params:xml:ns:carddav"/>
    #           <A:displayname/>
    #           <C:email-address-set xmlns:C="http://calendarserver.org/ns/"/>
    #           <A:principal-collection-set/>
    #           <A:principal-URL/>
    #           <A:resource-id/>
    #           <A:supported-report-set/>
    #         </A:prop>
    #         </A:propfind>
    #     """, depth: 0

    #     it 'contains a ref to the addressbook set', ->
    #         ref = '<card:addressbook-home-set><d:href>' +
    #               '/public/webdav/addressbooks/me/' +
    #               '</d:href></card:addressbook-home-set>'
    #         @resbody.should.have.string ref

    describe 'Android PROPFIND /public/webdav/addressbooks/me/', ->

        before helpers.send 'PROPFIND', '/public/addressbooks/me', """
            <?xml version="1.0" encoding="utf-8" ?>
            <A:propfind xmlns:A="DAV:">
                <A:prop><A:displayname/><A:resourcetype/></A:prop>
            </A:propfind>
        """, depth: 1

        it 'contains ref to the addressbook', ->

            ref = '<d:href>/public/webdav/addressbooks/me/all-contacts/</d:href>'
            refName = '<d:displayname>Cozy Contacts</d:displayname>'
            refType = '<d:resourcetype><d:collection/><card:addressbook/></d:resourcetype>'

            @resbody.should.have.string ref
            @resbody.should.have.string refName
            @resbody.should.have.string refType

    describe 'Apple PROPFIND /public/webdav/addressbooks/me/', ->

        before helpers.send 'PROPFIND', '/public/addressbooks/me', """
            <?xml version="1.0" encoding="utf-8" ?>
            <A:propfind xmlns:A="DAV:">
            <A:prop>
                <A:add-member/>
                <D:bulk-requests xmlns:D="http://me.com/_namespace/"/>
                <A:current-user-privilege-set/>
                <A:displayname/>
                <B:max-image-size xmlns:B="urn:ietf:params:xml:ns:carddav"/>
                <B:max-resource-size xmlns:B="urn:ietf:params:xml:ns:carddav"/>
                <C:me-card xmlns:C="http://calendarserver.org/ns/"/>
                <A:owner/>
                <C:push-transports xmlns:C="http://calendarserver.org/ns/"/>
                <C:pushkey xmlns:C="http://calendarserver.org/ns/"/>
                <A:quota-available-bytes/>
                <A:quota-used-bytes/>
                <A:resource-id/>
                <A:resourcetype/>
                <A:supported-report-set/>
                <A:sync-token/>
            </A:prop>
            </A:propfind>
        """, depth: 1

        it 'contains ref to the addressbook', ->

            ref = '<d:href>/public/webdav/addressbooks/me/all-contacts/</d:href>'
            refName = '<d:displayname>Cozy Contacts</d:displayname>'
            refType = '<d:resourcetype><d:collection/><card:addressbook/></d:resourcetype>'

            @resbody.should.have.string ref
            @resbody.should.have.string refName
            @resbody.should.have.string refType

    describe 'Apple PROPFIND /public/webdav/calendars/me/ D=1', ->

        before helpers.send 'PROPFIND', '/public/calendars/me/', """
            <?xml version="1.0" encoding="UTF-8"?>
            <A:propfind xmlns:A="DAV:">
              <A:prop>
                <A:add-member/>
                <C:allowed-sharing-modes xmlns:C="http://calendarserver.org/ns/"/>
                <D:bulk-requests xmlns:D="http://me.com/_namespace/"/>
                <E:calendar-color xmlns:E="http://apple.com/ns/ical/"/>
                <B:calendar-description xmlns:B="urn:ietf:params:xml:ns:caldav"/>
                <B:calendar-free-busy-set xmlns:B="urn:ietf:params:xml:ns:caldav"/>
                <E:calendar-order xmlns:E="http://apple.com/ns/ical/"/>
                <B:calendar-timezone xmlns:B="urn:ietf:params:xml:ns:caldav"/>
                <A:current-user-privilege-set/>
                <B:default-alarm-vevent-date xmlns:B="urn:ietf:params:xml:ns:caldav"/>
                <B:default-alarm-vevent-datetime xmlns:B="urn:ietf:params:xml:ns:caldav"/>
                <A:displayname/>
                <C:getctag xmlns:C="http://calendarserver.org/ns/"/>
                <A:owner/>
                <C:pre-publish-url xmlns:C="http://calendarserver.org/ns/"/>
                <C:publish-url xmlns:C="http://calendarserver.org/ns/"/>
                <C:push-transports xmlns:C="http://calendarserver.org/ns/"/>
                <C:pushkey xmlns:C="http://calendarserver.org/ns/"/>
                <A:quota-available-bytes/>
                <A:quota-used-bytes/>
                <E:refreshrate xmlns:E="http://apple.com/ns/ical/"/>
                <A:resource-id/>
                <A:resourcetype/>
                <B:schedule-calendar-transp xmlns:B="urn:ietf:params:xml:ns:caldav"/>
                <B:schedule-default-calendar-URL xmlns:B="urn:ietf:params:xml:ns:caldav"/>
                <C:source xmlns:C="http://calendarserver.org/ns/"/>
                <C:subscribed-strip-alarms xmlns:C="http://calendarserver.org/ns/"/>
                <C:subscribed-strip-attachments xmlns:C="http://calendarserver.org/ns/"/>
                <C:subscribed-strip-todos xmlns:C="http://calendarserver.org/ns/"/>
                <B:supported-calendar-component-set xmlns:B="urn:ietf:params:xml:ns:caldav"/>
                <B:supported-calendar-component-sets xmlns:B="urn:ietf:params:xml:ns:caldav"/>
                <A:supported-report-set/>
                <A:sync-token/>
                <C:xmpp-server xmlns:C="http://calendarserver.org/ns/"/>
                <C:xmpp-uri xmlns:C="http://calendarserver.org/ns/"/>
              </A:prop>
            </A:propfind>
        """, depth: 1

        it 'contains ref to the calendar', ->

            ref = '<d:href>/public/webdav/calendars/me/my-calendar/</d:href>'
            refName = '<d:displayname>Cozy Calendar</d:displayname>'
            refType = '<d:resourcetype><d:collection/><cal:calendar/></d:resourcetype>'

            @resbody.should.have.string ref
            @resbody.should.have.string refName
            @resbody.should.have.string refType


