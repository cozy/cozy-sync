americano = require 'americano-cozy'
VCardParser = require 'cozy-vcard'


module.exports = Contact = americano.getModel 'Contact',
    id            : String
    carddavuri    : String
    fn            : String
    n             : String
    datapoints    : Object
    note          : String
    _attachments  : Object

Contact::getURI = -> @carddavuri or @id + '.vcf'
Contact.all = (cb) -> Contact.request 'byURI', cb
Contact.byURI = (uri, cb) ->
    # see alarms for complexity
    req = Contact.request 'byURI', null, cb
    req.body = JSON.stringify key: uri
    req.setHeader 'content-type', 'application/json'

Contact::toVCF = ->
    return VCardParser.toVCF @toJSON()

Contact.parse = (vcf) ->
    parser = new VCardParser()
    parser.read vcf
    return new Contact parser.contacts[0]
