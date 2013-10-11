jsDAV = require "jsDAV"
jsDAV.debugMode = true


# Auth
cozy_Auth_Backend            = require './backends/auth'

# Permissions
jsDAVACL_PrincipalCollection = require "jsDAV/lib/DAVACL/principalCollection"
cozy_PrincipalBackend        = require './backends/principal'
principalBackend             = new cozy_PrincipalBackend
nodePrincipalCollection      = jsDAVACL_PrincipalCollection.new(principalBackend)

# Contacts
jsCardDAV_AddressBookRoot    = require "jsDAV/lib/CardDAV/addressBookRoot"
cozy_CardBackend             = require './backends/carddav'
carddavBackend               = new cozy_CardBackend require './models/contact'
nodeCardDAV                  = jsCardDAV_AddressBookRoot.new(principalBackend, carddavBackend)

# Calendar
jsCalDAV_CalendarRoot        = require "jsDAV/lib/CalDAV/calendarRoot"
cozy_CalBackend              = require './backends/caldav'
caldavBackend                = new cozy_CalBackend
    Alarm: require './models/alarm'
    Event: require './models/event'
    User:  require './models/user'
nodeCalDAV                   = jsCalDAV_CalendarRoot.new(principalBackend, caldavBackend)


# Init DAV Server
DAVServer = jsDAV.mount
    server: true
    standalone: false

    realm: 'jsDAV'
    mount: '/public/webdav/'

    authBackend: cozy_Auth_Backend.new()
    plugins: [
        require "jsDAV/lib/DAV/plugins/auth"
        require "jsDAV/lib/CardDAV/plugin"
        require "jsDAV/lib/CalDAV/plugin"
        require "jsDAV/lib/DAVACL/plugin"
    ]

    node: [nodePrincipalCollection, nodeCardDAV, nodeCalDAV]


# Include UI then run server
module.exports = app = require('./app')(DAVServer)
port = process.env.PORT || 9116
host = process.env.HOST || "127.0.0.1"

unless module.parent
    app.start port, host, (err) ->
        if err
            console.log "Not started because : "
            console.log err
        else
            console.log "WebDAV Server listening on %s:%d within %s environment",
                        host, port, app.get('env')
