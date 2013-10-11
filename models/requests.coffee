async = require('async')
module.exports = (done) ->

    byURI =     (doc) -> emit (doc.caldavuri or doc._id + '.ics'), doc
    byCardURI = (doc) -> emit (doc.carddavuri or doc._id + '.vcf'), doc
    all   =     (doc) -> emit doc._id, doc

    models =
        'event':         'byURI': byURI
        'alarm':         'byURI': byURI
        'contact':       'byURI': byCardURI
        'webdavaccount': 'all'  : all
        'user':          'all'  : all
        'cozy_instance':  'all'  : all

    ops = []

    addOp = (model, name, request) ->
        ops.push (cb) ->
            model = require("./#{model}")
            model.defineRequest name, request, (err) ->
                console.log err if err
                cb err

    for model, requests of models
        for name, request of requests
            addOp model, name, request

    async.series ops, done