americano = require 'americano'

port = process.env.PORT || 9116
host = process.env.HOST || "127.0.0.1"

if not module.parent
    americano.start name: 'webdav', port: port, (app) ->

        console.log "WebDAV Server listening on %s:%d within %s environment",
                    host, port, app.get('env')
