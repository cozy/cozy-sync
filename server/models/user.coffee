cozydb = require 'cozydb'
log = require('printit')
    date: true
    prefix: 'user:model'

module.exports = User = cozydb.getModel 'User',
    timezone: type: String, default: "Europe/Paris"

User.getTimezone = (callback) ->
    User.all (err, users) ->
        return callback err if err
        callback null, users?[0]?.timezone or "Europe/Paris"

User.updateUser = (callback) ->
    User.getTimezone (err, timezone) ->
        if err
            message = "Something went wrong during timezone retrieval -- #{err}"
            log.error message
            User.timezone = 'Europe/Paris'
        else
            User.timezone = timezone or "Europe/Paris"
        callback?()
