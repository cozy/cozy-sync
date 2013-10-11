# Interface = require 'jsdav/lib/CardDAV/interfaces/iBackend'
Exc       = require 'jsDAV/lib/shared/exceptions'

handle    = (err) ->
    console.log err
    return new Exc err.message || err

module.exports = class CozyCardDAVBackend

    constructor: (@Contact) ->

    getAddressBooksForUser: (principalUri, callback) ->
        book =
            id: 'all-contacts'
            uri: 'all-contacts'
            ctag: 0 # ?
            principaluri: principalUri
            "{DAV:}displayname": 'Cozy Contacts'

        return callback null, [book]

    getCards: (addressbookId, callback) ->
        @Contact.all (err, contacts) ->
            return callback handle err if err

            callback null, contacts.map (contact) ->
                lastmodified: 0
                carddata:     contact.toVCF()
                uri:          contact.getURI()

    getCard: (addressBookId, cardUri, callback) ->
        @Contact.byURI cardUri, (err, contact) ->
            return callback handle err if err
            return callback null unless contact.length

            contact = contact[0]

            callback null,
                lastmodified: 0
                carddata:     contact.toVCF()
                uri:          contact.getURI()

    createCard: (addressBookId, cardUri, cardData, callback) ->
        contact = @Contact.parse(cardData)
        contact.carddavuri = cardUri
        @Contact.create contact, (err, contact) ->
            return callback handle err if err

            callback null

    updateCard: (addressBookId, cardUri, cardData, callback) ->
        @Contact.byURI cardUri, (err, contact) =>
            return callback handle err if err
            return callback handle 'Not Found' unless contact.length

            contact = contact[0]
            data = @Contact.parse(cardData)
            data.carddavuri = cardUri

            contact.updateAttributes data, (err, contact) ->
                return callback handle err if err

                callback null

    deleteCard: (addressBookId, cardUri, callback) ->

        @Contact.byURI cardUri, (err, contact) ->
            return callback handle err if err

            contact = contact[0]

            contact.destroy (err) ->
                return callback handle err if err

                callback null
