// Generated by CoffeeScript 2.5.1
var Tools;

Tools = (function() {
  var isArr, t;

  class Tools {
    static isBoolean(v) {
      return t.call(v) === '[object Boolean]';
    }

    static isString(v) {
      return t.call(v) === '[object String]';
    }

    static isObject(v) {
      return t.call(v) === '[object Object]';
    }

    static isFunction(v) {
      return t.call(v) === '[object Function]';
    }

    static isNumber(v) {
      return v === v && (t.call(v) === '[object Number]'); // NaN === NaN -> false
    }

    static typeOf(v) {
      return t.call(v).slice(8, -1); // Attention! typeOf(NaN) === 'Number'
    }

    static null(o) {
      return Object.assign(Object.create(null), o);
    }

  };

  t = Object.prototype.toString;

  isArr = Array.isArray;

  // @isArray:       (v) -> isArr v                                      # t.call(v) is '[object Array]'
  Tools.isArray = Array.isArray;

  return Tools;

}).call(this);

// @isBoolean.type = 'Boolean'
// @isString.type = 'String'
// @isArray.type = 'Array'         # <- Reason of wrapping of Array.isArray
// @isObject.type = 'Object'
// @isFunction.type = 'Function'
// @isNumber.type = 'Number'

//# sourceMappingURL=Tools.js.map
