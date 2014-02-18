account = require './account'

module.exports =
    '':
        get: account.index
    'token':
        get: account.getCredentials
        post: account.createCredentials
