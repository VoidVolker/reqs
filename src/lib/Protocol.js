// Generated by CoffeeScript 2.5.1
  // Base classes for all requests types.
  // 1. For requests creation from incoming data
  // 2. Default data type for sending

// Requests types
var Model, Protocol, ReqsCallback, ReqsError, ReqsInfo, ReqsMethod, ReqsReject, ReqsRequest, ReqsResolve, types,
  hasProp = {}.hasOwnProperty;

types = {
  none: 0,
  method: 1,
  callback: 2,
  resolve: 3,
  reject: 4,
  error: 5,
  info: 6,
  0: 'none',
  1: 'method',
  2: 'callback',
  3: 'resolve',
  4: 'reject',
  5: 'error',
  6: 'info'
};

Model = (function() {
  var Property;

  class Model {
    constructor(props) {
      var name, prop;
      this.props = [];
      for (name in props) {
        if (!hasProp.call(props, name)) continue;
        prop = props[name];
        this.props.push(new Property(name, prop));
      }
    }

    validate(protocol, object) {
      var j, len, prop, ref;
      ref = this.props;
      for (j = 0, len = ref.length; j < len; j++) {
        prop = ref[j];
        prop.validate(protocol, object);
      }
      return this;
    }

    static required(type, props = {}) {
      return Object.assign(props, {
        type: type,
        required: true
      });
    }

  };

  Property = class Property {
    /*
    @class
    @param {string} name — property name
    @param {string} optionsOrType — property type
    @param {object} optionsOrType — property options:
        {array} types — list of allowed property types
        {boolean} [required] — is property required in object or not
        {object} [value] — value property for Array type value
        {object} [props] — properties for object type
    */
    constructor(name1, optionsOrType) {
      var j, len, name, options, prop, ref, ref1, t;
      this.name = name1;
      if (Tools.isString(optionsOrType)) {
        options = {
          type: [optionsOrType]
        };
      } else {
        options = optionsOrType;
        if (Tools.isString(options.type)) {
          options.type = [options.type];
        }
      }
      this.type = Tools.null();
      ref = options.type;
      for (j = 0, len = ref.length; j < len; j++) {
        t = ref[j];
        this.type[t] = true;
      }
      this.required = options.required !== void 0 ? options.required : false;
      // for array type
      if (options.value) {
        this.value = new Property(null, options.value);
      }
      // for object type
      if (options.props) {
        this.props = [];
        ref1 = options.props;
        for (name in ref1) {
          if (!hasProp.call(ref1, name)) continue;
          prop = ref1[name];
          this.props.push(new Property(name, prop));
        }
      }
    }

    validate(protocol, object, name, propPath) {
      var i, item, j, k, len, len1, prop, ref, type, value;
      name = this.name || name;
      if (this.required || Object.hasOwnProperty.call(object, name)) {
        value = object[name];
        type = Tools.typeOf(value);
        if (propPath) {
          if (Tools.isNumber(name)) {
            propPath += `[${name}]`;
          } else {
            propPath += `.${name}`;
          }
        } else {
          propPath = name;
        }
        // if @type.Key
        //     if type isnt 'String'
        //         protocol.throw "Key property type validation fail. Property: '#{propPath}'. Expected type: 'String'. Got type: '#{type}'."
        //     console.log 'Key:', value, propPath
        if (this.type[type] !== true) {
          types = Object.keys(this.type).join(', ');
          protocol.throw(`Request property type validation fail. Property: '${propPath}'. Expected types: '${types}'. Got type: '${type}'.`);
        }
        if (this.value && type === 'Array') {
          for (i = j = 0, len = value.length; j < len; i = ++j) {
            item = value[i];
            this.value.validate(protocol, value, i, propPath);
          }
        }
        if (this.props && type === 'Object') {
          ref = this.props;
          for (k = 0, len1 = ref.length; k < len1; k++) {
            prop = ref[k];
            prop.validate(protocol, value, null, propPath);
          }
        }
      }
      return this;
    }

  };

  Model.Property = Property;

  return Model;

}).call(this);

ReqsRequest = class ReqsRequest {
  constructor(type1) {
    this.type = type1;
  }

};

// args = [ a...n ] - method argument list,
// each argument can be callback function presented as string 'callback ID'
// cbs = 'callbacks list' [ num_0...num_n ], callbacks postions in arguments list
// OR
// id = callback ID
ReqsMethod = class ReqsMethod extends ReqsRequest {
  /*
  @class
  @param {string} method — method name
  @param {array} [args] — arguments list
  @param {array} [cbs] — list of callbacks positions in arguments list (argument - callback ID).
  @param {string} [id] — callback ID, if id is ommited - response is ommited too.
  'Id' is used when sender want to get returned value of calling method.
  'cbs' is used when sender client function was called with callbacks in arguments.
  This logic allow to have several responses to one call - as callback and as returned value.
  */
  constructor(method, id, args, cbs) {
    super(types.method);
    this.method = method;
    if (id) {
      this.id = id;
    }
    if (args) {
      this.args = args;
    }
    if (cbs) {
      this.cbs = cbs;
    }
  }

};

ReqsCallback = class ReqsCallback extends ReqsRequest {
  /*
  @class
  @param {string} id — callback's ID: this is result of method or callback executing
  @param {array} [args] — arguments list
  @param {array} [cbs] — callbacks positions in arguments (value - callback ID)
  */
  constructor(id1, args, cbs) {
    super(types.callback);
    this.id = id1;
    if (args) {
      this.args = args;
    }
    if (cbs) {
      this.cbs = cbs;
    }
  }

};

ReqsResolve = class ReqsResolve extends ReqsRequest {
  /*
  @class
  @param {string} id — callback's ID: this is result of method or callback executing
  @param {object} resolve — result
  */
  constructor(id1, resolve) {
    super(types.resolve);
    this.id = id1;
    this.resolve = resolve;
  }

};

ReqsReject = class ReqsReject extends ReqsRequest {
  /*
  @class
  @param {string} id — callback's ID: this is result of method or callback executing
  @param {object} reject — result
  */
  constructor(id1, reject) {
    super(types.reject);
    this.id = id1;
    this.reject = reject;
  }

};

ReqsError = class ReqsError extends ReqsRequest {
  constructor(message = '', code = null, id) {
    super(types.error);
    this.message = message;
    this.code = code;
    if (id) {
      this.id = id;
    }
  }

};

ReqsInfo = class ReqsInfo extends ReqsRequest {
  /*
  @class
  @param {string} id — callback's ID: this is result of method or callback executing
  @param {string[]} [events] — list of events (for client's api)
  @param {string[]} [methods] — list of methods (for client's api)
  */
  constructor(id1, events, methods) {
    super(types.info);
    this.id = id1;
    if (events) {
      this.events = events;
    }
    if (methods) {
      this.methods = methods;
    }
  }

};

Protocol = (function() {
  class Protocol {
    constructor(options1 = {}) {
      this.options = options1;
      this.model = {
        request: new Model({
          type: Model.required('Number')
        }),
        method: new Model({
          method: Model.required('String'),
          id: 'String',
          args: 'Array',
          cbs: 'Array'
        }),
        callback: new Model({
          id: Model.required('String'),
          args: 'Array',
          cbs: 'Array'
        }),
        promise: new Model({
          id: Model.required('String')
        }),
        error: new Model({
          message: Model.required('String'),
          code: 'Number',
          id: 'String'
        }),
        info: new Model({
          id: Model.required('String'),
          events: 'Array',
          methods: 'Array'
        })
      };
    }

    throw(msg) {
      throw new Error(`Protocol processing error: ${msg}`);
    }

    // Request parsing and validation
    parse(request) {
      var r;
      this.model.request.validate(this, request);
      switch (request.type) {
        case types.method:
          this.model.method.validate(this, request);
          r = new ReqsMethod(request.method, request.id, request.args, request.cbs);
          break;
        case types.callback:
          this.model.callback.validate(this, request);
          r = new ReqsCallback(request.id, request.args, request.cbs);
          break;
        case types.resolve:
          this.model.promise.validate(this, request);
          r = new ReqsResolve(request.id, request.resolve);
          break;
        case types.reject:
          this.model.promise.validate(this, request);
          r = new ReqsReject(request.id, request.reject);
          break;
        case types.error:
          this.model.error.validate(this, request);
          r = new ReqsError(request.message, request.code, request.id);
          break;
        case types.info:
          this.model.info.validate(this, request);
          r = new ReqsInfo(request.id, request.events, request.methods);
          break;
        default:
          r = this.throw(`Unknown request type: ${request.type}`);
      }
      return r;
    }

  };

  Protocol.category = 'protocols';

  Protocol.option = 'coder';

  Protocol.types = types;

  Protocol.prototype.types = types;

  Protocol.Model = Model;

  // Request creation constructors (executes in Protocol's context)
  /*
  Create method request, constructor
  @class
  @param {string} methodName — method name
  @param {string} id — id of the request
  @param {array} arguments — method arguments
  @param {array} cbs — callbacks ID positions in arguments
  @return {object} request — builded request
  */
  Protocol.prototype.Method = ReqsMethod;

  Protocol.Method = ReqsMethod;

  /*
  Create callback request, constructor
  @class
  @param {string} id — id of the request
  @param {array} arguments — callback arguments
  @param {array} cbs — callbacks ID positions in arguments
  @return {object} request — builded request
  */
  Protocol.prototype.Callback = ReqsCallback;

  Protocol.Callback = ReqsCallback;

  /*
  Create promise resolve request, constructor
  @class
  @param {string} id — id of the request
  @param {object} result — result object
  @return {object} request — builded request
  */
  Protocol.prototype.Resolve = ReqsResolve;

  Protocol.Resolve = ReqsResolve;

  /*
  Create promise reject request, constructor
  @class
  @param {string} id — id of the request
  @param {object} reject — reject object
  @return {object} request — builded request
  */
  Protocol.prototype.Reject = ReqsReject;

  Protocol.Reject = ReqsReject;

  /*
  Create error request, constructor
  @class
  @param {string} message — error message
  @param {number} code — error code
  @param {string} id — id of the request
  @return {object} request — builded request
  */
  Protocol.prototype.Error = ReqsError;

  Protocol.Error = ReqsError;

  /*
  Create info request, constructor
  @class
  @param {string} id — id of the request
  @param {array} events — server's events list (methods at client side)
  @param {array} methods — server's methods list (events at client side)
  @return {object} request — builded request
  */
  Protocol.prototype.Info = ReqsInfo;

  Protocol.Info = ReqsInfo;

  return Protocol;

}).call(this);

//# sourceMappingURL=Protocol.js.map
