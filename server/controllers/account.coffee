fs = require 'fs'
path = require 'path'
WebDAVAccount = require '../models/webdavaccount'
CozyInstance = require '../models/cozyinstance'
shortId = require 'shortid'

davAccount = null
WebDAVAccount.first (err, account) ->
    if account? then davAccount = account
    else davAccount = null

cozyInstance = null
CozyInstance.first (err, instance) ->
    if instance? then cozyInstance = instance
    else cozyInstance = null

module.exports =
    index: (req, res) ->
        locale = cozyInstance?.locale or 'en'

        filename = "index_#{locale}"
        filePath = path.resolve __dirname, "../views/#{filename}.jade"
        try
            stats = fs.lstatSync filePath
        catch e
            filename = "index_en"

        domain = if cozyInstance? then cozyInstance.domain else 'your.cozy.url'
        data =
            login: davAccount?.login
            password: davAccount?.password
            domain: domain
        res.render filename, data

    getCredentials: (req, res) ->
        if davAccount?
            res.send davAccount.toJSON()
        else
            res.send error: true, msg: 'No webdav account generated', 404

    createCredentials: (req, res) ->
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
