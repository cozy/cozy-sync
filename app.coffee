shortId = require 'shortid'
express = require 'express'
WebDAVAccount = require './models/webdavaccount'
CozyInstance = require './models/cozy_instance'


module.exports = (davServer) ->
    app = express()
    app.set 'view engine', 'jade'

    # /public is the WebDAV server
    app.use '/public', (req, res) ->
        # jsDAV need to know the true client url
        req.url = "/public/webdav#{req.url}"
        davServer.exec req, res

    app.use express.static(__dirname + '/public')
    app.use express.logger 'dev'
    app.use express.errorHandler
        dumpExceptions: true
        showStack: true

    # Load davaccount and cozy instance on requests
    app.use (req, res, next) ->
        WebDAVAccount.first (err, davAccount) ->
            return next err if err
            req.davAccount = davAccount
            CozyInstance.first (err, cozyInstance) ->
                req.cozyInstance = cozyInstance
                next err

    app.use (req, res, next) ->
        res.error = (code, msg, err) ->
            if msg.stack
                err = msg
                msg = err.message
            console.log err.stack if err
            res.send error: true, msg: msg, code

        next()


    # Index page
    app.get '/', (req, res) ->
        data =
            login: req.davAccount?.login       or 'me'
            password: req.davAccount?.password or 'Use button below to reset'
            domain: req.cozyInstance?.domain   or 'your.cozy.url'
        res.render 'index', data

    # Get credentials
    app.get '/token', (req, res) ->
        if req.davAccount
            res.send account.toJSON()
        else
            res.error 404, 'No webdav account generated'

    # Generate credentials
    app.post '/token', (req, res) ->
        login = 'me'
        password = shortId.generate()
        data = login: login, password: password

        if not req.davAccount
            WebDAVAccount.create data, (err, account) ->
                if err
                    res.error 500, err
                else
                    res.send success: true, account: account.toJSON()
        else
            req.davAccount.updateAttributes data, (err) ->
                if err
                    res.error 500, err
                else
                    res.send success: true, account: davAccount.toJSON()

    app.start = ->
        initRequests = require './models/requests'
        args = arguments
        initRequests (err) ->
            if err
                callback = args[args.length-1]
                return callback err
            else
                app.server = app.listen.apply app, args

        return app

    app.close = ->
        app.server.close()

    return app