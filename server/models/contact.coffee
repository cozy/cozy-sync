fs = require 'fs'
cozydb = require 'cozydb'
WritableStream = require('stream').Writable
VCardParser = require 'cozy-vcard'
log = require('printit')
    date: true
    prefix: 'model:contact'


class DataPoint extends cozydb.Model
    @schema:
        name: String
        value: cozydb.NoSchema
        type: String
        mediatype: String

module.exports = Contact = cozydb.getModel 'Contact',
    id            : String
    carddavuri    : String
    fn            : String
    n             : String
    datapoints    : [DataPoint]
    note          : String
    tags          : [String]
    _attachments  : Object
    org           : String
    title         : String
    department    : String
    bday          : String
    nickname      : String
    url           : String
    revision      : Date

Contact.afterInitialize = ->
    # Cleanup the model,
    # Defensive against data from DataSystem

    # n and fn MUST be valid.
    if not @n? or @n is ''
        if not @fn?
            @fn = ''

        @n = VCardParser.fnToN(@fn).join ';'

    else if not @fn? or @fn is ''
        @fn = VCardParser.nToFN @n.split ';'

    return @


Contact::getURI = -> @carddavuri or @id + '.vcf'


Contact.all = (cb) -> Contact.request 'byURI', cb


Contact.byURI = (uri, cb) ->
    # see alarms for complexity
    Contact.request 'byURI', key: uri, cb


Contact::addTag = (tag) ->
    @tags = [] unless @tags?

    if @tags.indexOf tag is -1
        @tags.push tag


Contact.byTag = (tag, callback) ->
    Contact.request 'byTag', key: tag, callback


Contact.tags = (callback) ->
    Contact.rawRequest "tags", group: true, (err, results) ->
        return callback err, [] if err
        callback null, results.map (keyValue) -> return keyValue.key


Contact::toVCF = (callback) ->
    if @_attachments?.picture?
        # we get a stream that we need to convert into a buffer
        # so we can output a base64 version of the picture
        stream = @getFile 'picture', (err) ->
            callback err if err?
        chunks = []
        bufferer = new WritableStream
        bufferer._write = (chunk, enc, next) ->
            chunks.push(chunk)
            next()
        bufferer.on 'finish', =>
            picture = Buffer.concat(chunks).toString 'base64'
            callback null, VCardParser.toVCF(@, picture)
        stream.pipe bufferer
    else
        callback null, VCardParser.toVCF(@)


# Convert base64 encoded string a jpg file and upload it
# Then clean the temporarily created file
Contact::handlePhoto = (photo, callback) ->
    if photo? and photo.length > 0
        filePath = "/tmp/#{@id}.jpg"
        fs.writeFile filePath, photo, encoding: 'base64', (err) =>
            return callback err if err?
            @attachFile filePath, name: 'picture', (err) ->
                fs.unlink filePath, -> callback err
    else
        callback null


Contact.parse = (vcf) ->
    parser = new VCardParser()
    parser.read vcf
    contact = new Contact parser.contacts[0]
    contact.photo = parser.contacts[0].photo
    return contact
