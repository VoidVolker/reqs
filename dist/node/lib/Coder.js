Tools = require('./Tools')

// Generated by CoffeeScript 2.5.1
var Coder;

Coder = (function() {
  class Coder {
    encodeKey(request) {
      request.key = this.key;
      return JSON.stringify(request);
    }

    decodeKey(data) {
      var request;
      request = JSON.parse(data);
      if (request.key !== this.key) {
        throw new Error("Wrong API Key");
      }
      delete request.key;
      return request;
    }

    constructor(key) {
      if (key) {
        this.key = key;
        this.encode = this.encodeKey;
        this.decode = this.decodeKey;
      }
    }

  };

  Coder.category = 'coders';

  Coder.option = 'coder';

  /*
  Default encode function from object to data
  @param {object} object — object with request
  @return {string} data — output data; object, encoded to string/buffer/whatever format
  */
  Coder.prototype.encode = JSON.stringify;

  /*
  Default decode function from data to object
  @param {string} data — input request in string/buffer/whatever format
  @return {object} object — decoded object from data
  */
  Coder.prototype.decode = JSON.parse;

  return Coder;

}).call(this);

//# sourceMappingURL=Coder.js.map


module.exports = Coder
