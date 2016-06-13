cozydb = require 'cozydb'
log = require('printit')
    date: true
    prefix: 'tag:model'

module.exports = Tag = cozydb.getModel 'Tag',
    name : type: String
    color : type: String, default: '#008AF6'

Tag.byNames = (names, callback) ->
    Tag.request 'all', keys: names, callback

# Get a tag by name, or create the instance of it,
# but don't save it in database.
Tag.getOrCreateByName = (name, callback) ->

    createIt =  -> Tag.create name: name, callback

    Tag.request 'byName', key: name, (err, tags) ->
        if err
            log.error err
            createIt()
        else if tags.length is 0
            createIt()
        else
            callback null, tags[0]
