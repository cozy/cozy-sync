db = require './db'

module.exports = Contact = db.define 'Contact',
    id            : String
    carddavuri    : String
    fn            : String
    datapoints    : Object
    note          : String
    _attachments  : Object

byURI = (doc) -> emit (doc.carddavuri or doc._id + '.ics'), doc
Contact.defineRequest 'byURI', byURI, ->
    console.log 'Contact "byURI" request created'

Contact::getURI = -> @carddavuri or @id + '.ics'
Contact.byURI = (uri, cb) ->
    # see alarms for complexity
    req = Contact.request 'byURI', null, cb
    req.body = JSON.stringify key: uri
    req.setHeader 'content-type', 'application/json'

Contact::toVCF = ->

    model = @toJSON()


    out = "BEGIN:VCARD\n"
    out += "VERSION:3.0\n"
    out += "NOTE:#{model.note}\n" if model.note
    out += "FN:#{model.fn}\n"


    for i, dp of model.datapoints

        value = dp.value

        switch dp.name

            when 'about'
                if dp.type is 'org' or dp.type is 'title'
                    out += "#{dp.type.toUpperCase()}:#{value}\n"
                else
                    out += "X-#{dp.type.toUpperCase()}:#{value}\n"

            when 'other'
                out += "X-#{dp.type.toUpperCase()}:#{value}\n"

            else
                key = dp.name.toUpperCase()
                value = value.replace(/(\r\n|\n\r|\r|\n)/g, ";") if key is 'ADR'
                type = "TYPE=#{dp.type.toUpperCase()}"
                out += "#{key};#{type}:#{value}\n"


    out += "END:VCARD\n"

    out

AndroidToDP = (contact, raw) ->
    parts = raw.split ';'
    switch parts[0].replace 'vnd.android.cursor.item/', ''
        when 'contact_event'
            value = parts[1]
            type = if parts[2] in ['0', '2'] then parts[3]
            else if parts[2] is '1' then 'anniversary'
            else 'birthday'
            contact.addDP 'about', type, value
        when 'relation'
            # console.log parts
            value = parts[1]
            type = ANDROID_RELATION_TYPES[+parts[2]]
            # console.log type
            type = parts[3] if type is 'custom'
            contact.addDP 'other', type, value

Contact.parse = (vcf) ->

    # inspired by https://github.com/mattt/vcard.js

    regexps =
        begin:       /^BEGIN:VCARD$/i
        end:         /^END:VCARD$/i
        simple:      /^(version|fn|title|org|note)\:(.+)$/i
        android:     /^x-android-custom\:(.+)$/i
        composedkey: /^item(\d{1,2})\.([^\:]+):(.+)$/
        complex:     /^([^\:\;]+);([^\:]+)\:(.+)$/
        property:    /^(.+)=(.+)$/

    currentversion = "3.0"


    current = null
    currentidx = null
    currentdp = null

    addDP = (name, type, value) ->
        current.datapoints.push
            type: type
            name: name
            value: value

    for line in vcf.split /\r?\n/

        console.log "LINE : ", line

        if regexps.begin.test line
            console.log "b"
            current = {}
            current.datapoints = []

        else if regexps.end.test line
            console.log "ee"
            console.log currentdp
            current.datapoints.push currentdp if currentdp
            return current
            currentdp = null
            current = null
            currentidx = null
            currentversion = "3.0"

        else if regexps.simple.test line
            console.log "s"
            [all, key, value] = line.match regexps.simple

            key = key.toLowerCase()

            switch key
                when 'version' then currentversion = value
                when 'title', 'org'
                    current.addDP 'about', key, value
                when 'fn', 'note'
                    current[key] = value
                when 'bday'
                    current.addDP 'about', 'birthday', value

        else if regexps.android.test line
                [all, value] = line.match regexps.android
                # console.log 'androd', value
                AndroidToDP current, value

        else if regexps.composedkey.test line
            console.log "ck"
            [all, itemidx, part, value] = line.match regexps.composedkey

            if currentidx is null or currentidx isnt itemidx
                current.datapoints.push currentdp if currentdp
                currentdp = {}

            currentidx = itemidx

            part = part.split ';'
            key = part[0]
            properties = part.splice 1

            value = value.split(';')
            value = value[0] if value.length is 1

            key = key.toLowerCase()

            if key is 'x-ablabel' or key is 'x-abadr'
                value = value.replace '_$!<', ''
                value = value.replace '>!$_', ''
                currentdp.type = value.toLowerCase()
            else
                for property in properties
                    [all, pname, pvalue] = property.match regexps.property
                    currentdp[pname.toLowerCase()] = pvalue.toLowerCase()

                if key is 'adr'
                    value = value.join("\n").replace /\n+/g, "\n"

                if key is 'x-abdate'
                    key = 'about'

                if key is 'x-abrelatednames'
                    key = 'other'

                currentdp.name = key.toLowerCase()
                currentdp.value = value.replace "\\:", ":"

        else if regexps.complex.test line
            console.log "cpx"
            [all, key, properties, value] = line.match regexps.complex

            current.datapoints.push currentdp if currentdp
            currentdp = {}

            # console.log all, '-->', key, properties, value

            value = value.split(';')
            value = value[0] if value.length is 1

            key = key.toLowerCase()

            if key in ['email', 'tel', 'adr', 'url']
                currentdp.name = key
                if key is 'adr'
                    value = value.join("\n").replace /\n+/g, "\n"
            else
                currentdp = null
                continue

            properties = properties.split ';'

            # console.log "properties=", properties

            for property in properties
                match = property.match regexps.property
                if match then [all, pname, pvalue] = match
                else
                    pname = 'type'
                    pvalue = property

                if pname is 'type' and pvalue is 'pref'
                    currentdp.pref = 1
                else
                    currentdp[pname.toLowerCase()] = pvalue.toLowerCase()

            currentdp.value = value

            console.log currentdp


    return imported