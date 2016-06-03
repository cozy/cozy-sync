fs = require 'fs'
path = require 'path'
async = require 'async'
WebDAVAccount = require '../models/webdavaccount'
CozyInstance = require '../models/cozyinstance'
Event = require '../models/event'
localizationManager = require '../helpers/localization_manager'
log = require('printit')
    prefix: 'account:controller'

# Get the template name for given locale, fallbacks to english template
getTemplateName = (locale) ->
    # If run from build/, templates are compiled to JS
    # otherwise, they are in jade
    filePath = path.resolve __dirname, '../views/index.js'
    runFromBuild = fs.existsSync filePath
    extension = if runFromBuild then 'js' else 'jade'

    fileName = "index.#{extension}"
    filePath = path.resolve __dirname, "../views/#{fileName}"
    fileName = "index.#{extension}" unless fs.existsSync(filePath)
    return fileName

module.exports =
    index: (req, res) ->
        async.parallel {
            davAccount: (done) -> WebDAVAccount.first done
            calendarTags: (done) -> Event.calendars done
            instance: (done) -> CozyInstance.first done
        }, (err, results) ->

            log.error err if err?

            {davAccount, calendarTags, instance} = results
            calendarNames = calendarTags?.map (calendar) -> calendar.name

            locale = instance?.locale or 'en'
            domain = instance?.domain or ''
            localizationManager.ensureReady (err) ->
                data =
                    login: davAccount?.login
                    token: davAccount?.token
                    domain: domain
                    calendars: calendarNames
                    webdav: localizationManager.t 'webdav'
                    standard: localizationManager.t 'standard protocol'
                    tutorials: localizationManager.t 'two tutorials'
                    contactsTutorial: localizationManager.t 'contacts tutorial'
                    server: localizationManager.t 'server credentials'
                    further: localizationManager.t 'before going further'
                    log: localizationManager.t 'login'
                    password: localizationManager.t 'password'
                    show: localizationManager.t 'show'
                    hide: localizationManager.t 'hide'
                    reset: localizationManager.t 'reset password'
                    dom: localizationManager.t 'domain'
                    calendarTutorial: localizationManager.t 'calendar'
                    client: localizationManager.t 'your client will ask for'
                    serverField: localizationManager.t 'in the server field'
                    android: localizationManager.t 'sync android'
                    select: localizationManager.t 'select a calendar'
                    url: localizationManager.t 'use the following url'
                    contacts: localizationManager.t 'contacts'
                    thunderbird: localizationManager.t 'sync thunderbird'
                    files: localizationManager.t 'WebDAV configuration (Files)'
                    file: localizationManager.t 'doesn\'t support file'
                    troubleshouting: localizationManager.t 'troubleshooting'
                    problems: localizationManager.t 'experimenting problems'
                    github: localizationManager.t 'on github'
                    calendar: localizationManager.t 'calendar'


                fileName = getTemplateName locale
                res.render fileName, data

    createCredentials: (req, res) ->
        WebDAVAccount.createAccount (err, account) ->
            if err?
                res.send 500, error: err.toString()
            else
                res.send 201, success: true, account: account.toJSON()
