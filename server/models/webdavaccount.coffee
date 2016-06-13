cozydb = require 'cozydb'
shortId = require 'shortid'

log = require('printit')
    date: true
    prefix: 'webdavaccount:model'

# Object required to store the automatically generated webdav credentials.
module.exports = WebDAVAccount = cozydb.getModel 'WebDAVAccount',
    id: String
    login: String
    token: String
    password: String # old token, kept for retrocompatiblity
    ctag: Number # used to keep track of changes in the calendar
    cardctag: Number # used to keep track of changes in the addressbook

WebDAVAccount.first = (callback) ->
    WebDAVAccount.request 'all', (err, accounts) ->
        if err then callback err
        else if not accounts or accounts.length is 0 then callback null, null
        else
            account = accounts[0]

            # Retrocompatibility, webdav account has no business
            # being encrypted, we rename the password field as token in the db
            if account?.password
                log.info "WEBDAVACCOUNT HAS A PASSWORD, PATCHING"
                account.token = account.password
                account.password = null
                account.save (err) ->
                    callback err, account

            else
                callback null, account


WebDAVAccount.set = (data, callback) ->
    WebDAVAccount.first (err, account) ->
        if not account?
            WebDAVAccount.create data, callback
        else
            account.updateAttributes data, callback

WebDAVAccount.createAccount = (callback) ->
    data =
        login: 'me'
        token: shortId.generate()

    WebDAVAccount.set data, callback
