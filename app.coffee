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

    # Init auth account
    davAccount = null
    WebDAVAccount.first (err, account) ->
        if account? then davAccount = account
        else davAccount = null

    # Init Cozy instance
    cozyInstance = null
    CozyInstance.first (err, instance) ->
        if instance? then cozyInstance = instance
        else cozyInstance = null

    # Index page
    app.get '/', (req, res) ->
        data =
            login: davAccount?.login       or 'me'
            password: davAccount?.password or 'Use button below to reset'
            domain: cozyInstance?.domain   or 'your.cozy.url'
        res.render 'index', data

    # Get credentials
    app.get '/token', (req, res) ->
        if davAccount?
            res.send account.toJSON()
        else
            res.send error: true, msg: 'No webdav account generated', 404

    # Generate credentials
    app.post '/token', (req, res) ->
        login = 'me'
        password = shortId.generate()
        data = login: login, password: password

        if not davAccount?
            WebDAVAccount.create data, (err, account) ->
                if err then res.send error: true, msg: err.toString(), 500
                else
                    davAccount = account
                    res.send success: true, account: account.toJSON()
        else
            davAccount.login = login
            davAccount.password = password
            davAccount.save (err) ->
                if err then res.send error: true, msg: err.toString(), 500
                else res.send success: true, account: davAccount.toJSON()

    app

