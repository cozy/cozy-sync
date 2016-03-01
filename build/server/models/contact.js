// Generated by CoffeeScript 1.10.0
var Contact, DataPoint, VCardParser, cozydb, fs, log, stream,
  extend = function(child, parent) { for (var key in parent) { if (hasProp.call(parent, key)) child[key] = parent[key]; } function ctor() { this.constructor = child; } ctor.prototype = parent.prototype; child.prototype = new ctor(); child.__super__ = parent.prototype; return child; },
  hasProp = {}.hasOwnProperty;

fs = require('fs');

cozydb = require('cozydb');

stream = require('stream');

VCardParser = require('cozy-vcard');

log = require('printit')({
  prefix: 'model:contact'
});

DataPoint = (function(superClass) {
  extend(DataPoint, superClass);

  function DataPoint() {
    return DataPoint.__super__.constructor.apply(this, arguments);
  }

  DataPoint.schema = {
    name: String,
    value: cozydb.NoSchema,
    type: String,
    mediatype: String
  };

  return DataPoint;

})(cozydb.Model);

module.exports = Contact = cozydb.getModel('Contact', {
  id: String,
  carddavuri: String,
  fn: String,
  n: String,
  datapoints: [DataPoint],
  note: String,
  tags: [String],
  _attachments: Object,
  org: String,
  title: String,
  department: String,
  bday: String,
  nickname: String,
  url: String,
  revision: Date
});

Contact.afterInitialize = function() {
  if ((this.n == null) || this.n === '') {
    if (this.fn == null) {
      this.fn = '';
    }
    this.n = VCardParser.fnToN(this.fn).join(';');
  } else if ((this.fn == null) || this.fn === '') {
    this.fn = VCardParser.nToFN(this.n.split(';'));
  }
  return this;
};

Contact.prototype.getURI = function() {
  return this.carddavuri || this.id + '.vcf';
};

Contact.all = function(cb) {
  return Contact.request('byURI', cb);
};

Contact.byURI = function(uri, cb) {
  return Contact.request('byURI', {
    key: uri
  }, cb);
};

Contact.prototype.addTag = function(tag) {
  if (this.tags == null) {
    this.tags = [];
  }
  if (this.tags.indexOf(tag === -1)) {
    return this.tags.push(tag);
  }
};

Contact.byTag = function(tag, callback) {
  return Contact.request('byTag', {
    key: tag
  }, callback);
};

Contact.tags = function(callback) {
  return Contact.rawRequest("tags", {
    group: true
  }, function(err, results) {
    if (err) {
      return callback(err, []);
    }
    return callback(null, results.map(function(keyValue) {
      return keyValue.key;
    }));
  });
};

Contact.prototype.toVCF = function(callback) {
  var bufferer, chunks, ref;
  if (((ref = this._attachments) != null ? ref.picture : void 0) != null) {
    stream = this.getFile('picture', function(err) {
      if (err != null) {
        return callback(err);
      }
    });
    chunks = [];
    bufferer = new stream.Writable;
    bufferer._write = function(chunk, enc, next) {
      chunks.push(chunk);
      return next();
    };
    bufferer.on('end', function() {
      var picture;
      picture = Buffer.concat(chunks).toString('base64');
      return callback(null, VCardParser.toVCF(this, picture));
    });
    return stream.pipe(bufferer);
  } else {
    return callback(null, VCardParser.toVCF(this));
  }
};

Contact.prototype.handlePhoto = function(photo, callback) {
  var filePath;
  if ((photo != null) && photo.length > 0) {
    filePath = "/tmp/" + this.id + ".jpg";
    return fs.writeFile(filePath, photo, {
      encoding: 'base64'
    }, (function(_this) {
      return function(err) {
        if (err != null) {
          return callback(err);
        }
        return _this.attachFile(filePath, {
          name: 'picture'
        }, function(err) {
          return fs.unlink(filePath, function() {
            return callback(err);
          });
        });
      };
    })(this));
  } else {
    return callback(null);
  }
};

Contact.parse = function(vcf) {
  var contact, parser;
  parser = new VCardParser();
  parser.read(vcf);
  contact = parser.contacts[0];
  return new Contact(parser.contacts[0]);
};
