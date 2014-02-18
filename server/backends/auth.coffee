# Interface = require 'jsdav/lib/CardDAV/interfaces/iBackend'
Exc = require 'cozy-jsdav-fork/lib/shared/exceptions'
BasicAuth = require 'cozy-jsdav-fork/lib/DAV/plugins/auth/abstractBasic'
WebDAVAccount = require '../models/webdavaccount'

module.exports = BasicAuth.extend

    validateUserPass: (username, password, cbvalidpass) ->
        WebDAVAccount.first (err, account) ->
            result = not err and account? and account.password is password
            cbvalidpass result
