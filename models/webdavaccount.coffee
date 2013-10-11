db = require './db'

# Object required to store the automatically generated webdav credentials.
module.exports = WebDAVAccount = db.define 'WebDAVAccount',
    id: String
    login: String
    password: String
    ctag: Number # used to keep track of changes in the calendar

WebDAVAccount.first = (callback) ->
    WebDAVAccount.request 'all', (err, accounts) ->
        if err then callback err
        else if not accounts or accounts.length is 0 then callback null, null
        else  callback null, accounts[0]
