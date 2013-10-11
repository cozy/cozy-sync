helpers = require './helpers'
should = require('chai').Should()

describe 'Basic DAV Structure', ->


    before helpers.cleanDB
    before helpers.startServer
    # before -> require('eyes').inspect @server
    # before helpers.closeServer
    # before helpers.startServer
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


