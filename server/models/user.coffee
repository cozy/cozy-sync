americano = require 'americano-cozy'

module.exports = User = americano.getModel 'User',
    timezone: type: String, default: "Europe/Paris"

User.getTimezone = (callback) ->
    User.all (err, users) ->
        return callback err if err
        callback null, users?[0]?.timezone or "Europe/Paris"
