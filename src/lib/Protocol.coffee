# Base classes for all requests types.
# 1. For requests creation from incoming data
# 2. Default data type for sending

# Requests types
types =
    none: 0
    method: 1
    callback: 2
    resolve: 3
    reject: 4
    error: 5
    info: 6
    0: 'none'
    1: 'method'
    2: 'callback'
    3: 'resolve'
    4: 'reject'
    5: 'error'
    6: 'info'

class Model
    class Property
        ###
        @class
        @param {string} name — property name
        @param {string} optionsOrType — property type
        @param {object} optionsOrType — property options:
            {array} types — list of allowed property types
            {boolean} [required] — is property required in object or not
            {object} [value] — value property for Array type value
            {object} [props] — properties for object type
        ###
        constructor: (@name, optionsOrType) ->
            if Tools.isString optionsOrType
                options = type: [optionsOrType]
            else
                options = optionsOrType
                if Tools.isString options.type
                    options.type = [options.type]

            @type = Tools.null()
            for t in options.type
                @type[t] = true

            @required = if options.required isnt undefined then options.required else false

            # for array type
            if options.value
               @value = new Property null, options.value

            # for object type
            if options.props
                @props = []
                for own name, prop of options.props
                    @props.push new Property name, prop

        validate: (protocol, object, name, propPath) ->
            name = @name or name
            if @required or Object.hasOwnProperty.call object, name
                value = object[name]
                type = Tools.typeOf value

                if propPath
                    if Tools.isNumber name
                        propPath += "[#{name}]"
                    else
                        propPath += ".#{name}"
                else
                    propPath = name

                # if @type.Key
                #     if type isnt 'String'
                #         protocol.throw "Key property type validation fail. Property: '#{propPath}'. Expected type: 'String'. Got type: '#{type}'."
                #     console.log 'Key:', value, propPath

                if @type[type] isnt true
                    types = Object.keys( @type ).join ', '
                    protocol.throw "Request property type validation fail. Property: '#{propPath}'. Expected types: '#{types}'. Got type: '#{type}'."

                if @value and type is 'Array'
                    for item, i in value
                        @value.validate protocol, value, i, propPath

                if @props and type is 'Object'
                    for prop in @props
                        prop.validate protocol, value, null, propPath
            return @

    @Property: Property

    constructor: (props) ->
        @props = []
        for own name, prop of props
            @props.push new Property name, prop

    validate: (protocol, object) ->
        for prop in @props
            prop.validate protocol, object
        return @

    @required: (type, props = {}) ->
        Object.assign props,
            type: type
            required: true


class ReqsRequest
    constructor: (@type) ->

# args = [ a...n ] - method argument list,
# each argument can be callback function presented as string 'callback ID'
# cbs = 'callbacks list' [ num_0...num_n ], callbacks postions in arguments list
# OR
# id = callback ID
class ReqsMethod extends ReqsRequest
    ###
    @class
    @param {string} method — method name
    @param {array} [args] — arguments list
    @param {array} [cbs] — list of callbacks positions in arguments list (argument - callback ID).
    @param {string} [id] — callback ID, if id is ommited - response is ommited too.
    'Id' is used when sender want to get returned value of calling method.
    'cbs' is used when sender client function was called with callbacks in arguments.
    This logic allow to have several responses to one call - as callback and as returned value.
    ###
    constructor: (@method, id, args, cbs) ->
        super types.method
        if id then @id = id
        if args then @args = args
        if cbs then @cbs = cbs

class ReqsCallback extends ReqsRequest
    ###
    @class
    @param {string} id — callback's ID: this is result of method or callback executing
    @param {array} [args] — arguments list
    @param {array} [cbs] — callbacks positions in arguments (value - callback ID)
    ###
    constructor: (@id, args, cbs) ->
        super types.callback
        if args then @args = args
        if cbs then @cbs = cbs

class ReqsResolve extends ReqsRequest
    ###
    @class
    @param {string} id — callback's ID: this is result of method or callback executing
    @param {object} resolve — result
    ###
    constructor: (@id, @resolve) ->
        super types.resolve

class ReqsReject extends ReqsRequest
    ###
    @class
    @param {string} id — callback's ID: this is result of method or callback executing
    @param {object} reject — result
    ###
    constructor: (@id, @reject) ->
        super types.reject

class ReqsError extends ReqsRequest
    constructor: (@message = '', @code = null, id) ->
        super types.error
        if id then @id = id

class ReqsInfo extends ReqsRequest
    ###
    @class
    @param {string} id — callback's ID: this is result of method or callback executing
    @param {string[]} [events] — list of events (for client's api)
    @param {string[]} [methods] — list of methods (for client's api)
    ###
    constructor: (@id, events, methods) ->
        super types.info
        if events then @events = events
        if methods then @methods = methods

class Protocol
    @category: 'protocols'
    @option = 'coder'

    @types: types
    types: types

    constructor: (@options = {}) ->
        @model =
            request: new Model
                type: Model.required 'Number'
            method: new Model
                method: Model.required 'String'
                id: 'String'
                args: 'Array'
                cbs: 'Array'
            callback: new Model
                id: Model.required 'String'
                args: 'Array'
                cbs: 'Array'
            promise: new Model
                id: Model.required 'String'
            error: new Model
                message: Model.required 'String'
                code: 'Number'
                id: 'String'
            info: new Model
                id: Model.required 'String'
                events: 'Array'
                methods: 'Array'

    throw: (msg) -> throw new Error "Protocol processing error: #{msg}"

    # Request parsing and validation
    parse: (request) ->
        @model.request.validate @, request
        switch request.type
            when types.method
                @model.method.validate @, request
                r = new ReqsMethod request.method, request.id, request.args, request.cbs

            when types.callback
                @model.callback.validate @, request
                r = new ReqsCallback request.id, request.args, request.cbs

            when types.resolve
                @model.promise.validate @, request
                r = new ReqsResolve request.id, request.resolve

            when types.reject
                @model.promise.validate @, request
                r = new ReqsReject request.id, request.reject

            when types.error
                @model.error.validate @, request
                r = new ReqsError request.message, request.code, request.id

            when types.info
                @model.info.validate @, request
                r = new ReqsInfo request.id, request.events, request.methods

            else
                r = @throw "Unknown request type: #{request.type}"
        r

    @Model: Model

    # Request creation constructors (executes in Protocol's context)

    ###
    Create method request, constructor
    @class
    @param {string} methodName — method name
    @param {string} id — id of the request
    @param {array} arguments — method arguments
    @param {array} cbs — callbacks ID positions in arguments
    @return {object} request — builded request
    ###
    Method: ReqsMethod
    @Method: ReqsMethod

    ###
    Create callback request, constructor
    @class
    @param {string} id — id of the request
    @param {array} arguments — callback arguments
    @param {array} cbs — callbacks ID positions in arguments
    @return {object} request — builded request
    ###
    Callback: ReqsCallback
    @Callback: ReqsCallback

    ###
    Create promise resolve request, constructor
    @class
    @param {string} id — id of the request
    @param {object} result — result object
    @return {object} request — builded request
    ###
    Resolve: ReqsResolve
    @Resolve: ReqsResolve

    ###
    Create promise reject request, constructor
    @class
    @param {string} id — id of the request
    @param {object} reject — reject object
    @return {object} request — builded request
    ###
    Reject: ReqsReject
    @Reject: ReqsReject

    ###
    Create error request, constructor
    @class
    @param {string} message — error message
    @param {number} code — error code
    @param {string} id — id of the request
    @return {object} request — builded request
    ###
    Error: ReqsError
    @Error: ReqsError

    ###
    Create info request, constructor
    @class
    @param {string} id — id of the request
    @param {array} events — server's events list (methods at client side)
    @param {array} methods — server's methods list (events at client side)
    @return {object} request — builded request
    ###
    Info: ReqsInfo
    @Info: ReqsInfo
