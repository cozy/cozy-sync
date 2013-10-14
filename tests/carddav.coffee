helpers = require './helpers'
should = require('chai').Should()
xmldoc = require 'xmldoc'
Contact = require '../models/contact'

describe 'Carddav support', ->

    before require '../models/requests'
    before helpers.cleanDB
    before helpers.startServer
    before helpers.makeDAVAccount
    before helpers.createContact 'Bob'
    before helpers.createContact 'Steve'
    before ->
        url = '/public/webdav/addressbooks/me/all-contacts/'
        @bobHref   = url + @contacts['Bob'].id   + '.vcf'
        @steveHref = url + @contacts['Steve'].id + '.vcf'

    after  helpers.closeServer
    # after  helpers.cleanDB

    ### Not tested because part of jsDAV
       OPTIONS /public/webdav/addressbooks/me/all-contacts/
       PROPFIND /public/webdav/addressbooks/me/all-contacts/ DEPTH=0
    ###


    describe 'Android PROPFIND /public/webdav/addressbooks/me/all-contacts/ D=1', ->

        url = '/public/addressbooks/me/all-contacts/'
        before helpers.send 'PROPFIND', url, """
            <?xml version="1.0" encoding="utf-8" ?>
            <A:propfind xmlns:A="DAV:">
                <A:prop>
                    <A:getcontenttype/>
                    <A:getetag/>
                </A:prop>
            </A:propfind>
        """, depth: 1

        it 'contains a ref to each Contacts', ->

            body = new xmldoc.XmlDocument @resbody
            responses = body.childrenNamed 'd:response'
            responses.length.should.equal 3
            hrefs = responses.map (res) -> res.childNamed('d:href').val

            hrefs.should.include @bobHref
            hrefs.should.include @steveHref

    describe 'Android REPORT /public/webdav/addressbooks/me/all-contacts/', ->

        url = '/public/addressbooks/me/all-contacts/'
        before (done) ->
            helpers.send('REPORT', url, """
                <?xml version="1.0" encoding="utf-8" ?>
                <A:addressbook-multiget xmlns:B="DAV:" xmlns:A="urn:ietf:params:xml:ns:carddav">
                <B:prop>
                    <A:address-data/>
                    <B:getetag/>
                </B:prop>
                <B:href>#{@bobHref}</B:href>
                <B:href>#{@steveHref}</B:href>
                </A:addressbook-multiget>
            """).call @, done

        it 'contains contacts data', ->

            body = new xmldoc.XmlDocument @resbody
            responses = body.childrenNamed 'd:response'

            results = {}
            for res in responses
                href = res.childNamed('d:href')?.val
                propstat = res.childNamed('d:propstat')
                prop = propstat.childNamed('d:prop')
                card = prop.childNamed('card:address-data').val

                results[href] = card

            results[@bobHref].should.have.string 'bob@test.com'
            results[@steveHref].should.have.string 'steve@test.com'


    describe "Android Create contact", ->

        url = '/public/addressbooks/me/all-contacts/24edbec3-a2db-4b07-97d1-3609d526f4c8.vcf'
        before helpers.send 'PUT', url, """
            BEGIN:VCARD
            VERSION:3.0
            FN:Steve
            EMAIL;TYPE=INTERNET;TYPE=HOME:stw@test.com
            N:Wonder;;;;
            TEL;TYPE=CELL:+33 1 23 45 67 89
            PRODID:-//dmfs.org//mimedir.vcard//EN
            REV:20131011T070908Z
            UID:24edbec3-a2db-4b07-97d1-3609d526f4c8
            END:VCARD
        """,
            'If-None-Match': '*'
            'Content-Type': 'text/vcard; charset=utf-8'

        it "should work", ->
            @res.statusCode.should.equal 201
            @resbody.should.have.length 0

        it "and contact has been created in db", (done) ->
            Contact.byURI '24edbec3-a2db-4b07-97d1-3609d526f4c8.vcf', (err, contact) ->
                should.not.exist err
                contact.should.have.property.cardavuri
                done()

    describe "Android Check contact creation", ->

        url = '/public/addressbooks/me/all-contacts/24edbec3-a2db-4b07-97d1-3609d526f4c8.vcf'
        before helpers.send('HEAD', url, "")

        it "should return the contact E-tag", ->
            @res.statusCode.should.equal 200
            @res.headers.should.include.keys('etag')
            @etag = @res.headers['etag']

    describe "Android update created Contact", ->

        url = '/public/addressbooks/me/all-contacts/24edbec3-a2db-4b07-97d1-3609d526f4c8.vcf'
        before (done) ->
            helpers.send('PUT', url, """
                BEGIN:VCARD
                VERSION:3.0
                FN:Steve
                EMAIL;TYPE=INTERNET;TYPE=HOME:stw@test.com
                N:Wonder;;;;
                TEL;TYPE=CELL:+33 1 23 45 67 89
                PRODID:-//dmfs.org//mimedir.vcard//EN
                REV:20131011T070908Z
                UID:24edbec3-a2db-4b07-97d1-3609d526f4c8
                END:VCARD
            """, 'If-Match': @etag).call @, done

        it "should work", ->
            @res.statusCode.should.equal 200
            @resbody.should.have.length 0

        it "and contact has been updated in db", (done) ->
            Contact.byURI '24edbec3-a2db-4b07-97d1-3609d526f4c8.vcf', (err, contact) ->
                should.not.exist err
                contact.should.have.property.cardavuri
                done()

    describe "Android update Cozy Contact", ->

        url = '/public/addressbooks/me/all-contacts/926f1393b7e328e6992e54178903582c.vcf'
        before helpers.send 'PUT', url, """
            BEGIN:VCARD
            VERSION:3.0
            NOTE:some stuff about Bob
            FN:Bob
            TEL;TYPE=HOME:000
            EMAIL;TYPE=HOME:bob@test.com
            ADR;TYPE=HOME:Box3;Suite215;14 Avenue de la République;Compiègne;Picardie;60200;France
            UID:cf3250e4-bf00-484a-86bd-debc4d79e186
            TEL;TYPE=WORK:1 11 2
            N:;Bob;;;
            PRODID:-//dmfs.org//mimedir.vcard//EN
            REV:20131011T073813Z
            END:VCARD
        """

        it "should work", ->
            @res.statusCode.should.equal 201
            @resbody.should.have.length 0

        it "and contact has been updated in db", (done) ->

            Contact.byURI '926f1393b7e328e6992e54178903582c.vcf', (err, contact) ->
                should.not.exist err
                should.exist contact
                for dp in contact[0].datapoints
                    if dp.value is '1 11 2'
                        return done()
                    if dp.value is '1 11 1'
                        return done new Error('contact was not updated')



    describe "Android delete Contact", ->
        url = '/public/addressbooks/me/all-contacts/926f1393b7e328e6992e54178903582c.vcf'
        before helpers.send 'DELETE', url, ""

        it "should work", ->
            @res.statusCode.should.equal 204
            @resbody.should.have.length 0

        it "and contact has been deleted in db", (done) ->
            Contact.byURI '926f1393b7e328e6992e54178903582c.vcf', (err, contact) ->
                should.not.exist err
                should.not.exist contact[0]
                done()
