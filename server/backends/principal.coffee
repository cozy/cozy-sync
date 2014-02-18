
module.exports = class PrincipalBackend

    principal =
        uri:                 'principals/me'
        '{DAV:}displayname': 'cozy owner'

    getPrincipalsByPrefix: (prefixPath, callback) ->
        callback null, [principal]

    getPrincipalByPath: (path, callback) ->
        callback null, principal

    updatePrincipal: (path, mutations, callback) ->
        callback null, false

    searchPrincipals: (prefixPath, searchProperties, callback) ->
        callback null, [principal.uri]

    getGroupMemberSet: (principal, callback) ->
        callback null, [principal]

    getGroupMemberShip: (principal, callback) ->
        callback null, [principal]

    setGroupMemberSet: (principal, members, callback) ->
        callback null, false
