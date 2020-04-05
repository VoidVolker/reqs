###
Reqs class
@class
###
class Reqs
    # ####################### #
    # --- Default options --- #
    # ####################### #

    # Is methods async (returns promise) or not (returns options.send result)
    @default =
        mode: 'sync'
        coder: 'Coder'
        protocol: 'Protocol'

    # ############### #
    # --- Modules --- #
    # ############### #
    @protocols = Tools.null { Protocol }
    @coders = Tools.null { Coder }

    # ############################## #
    # --- Tools and constructors --- #
    # ############################## #
    @Tools = Tools
    @Protocol = Protocol
    @Coder = Coder

    # ################### #
    # --- Constructor --- #
    # ################### #

    ###
    Create Reqs API instance
    @constructor
    @param {object} options
    ###
    constructor: (options = {}) ->
        @events = Tools.null()
        @methods = Tools.null()
        @isSession = false
        @_callbacks = Tools.null()  # Callbacks container
        @_id = 0                    # Callbacks counter
        @_promises = Tools.null()   # Promises xt container
        @_pid = 0                   # Promises counter

        # Adding events handlers
        if options.events
            # Copy events handlers to object with nulled
            # __proto__ property for faster and safe search
            for own name, f of options.events
                @events[name] = f

        # Adding methods
        if options.methods
            @addMethods options.methods

        # Saving some options for inheritance
        # when session will be created
        @options =
            methods: options.methods or {}
            session: options.session

        # Setting send function
        if options.send
            @send = options.send

        # Processing error options
        if options.error
            @error = options.error

        # ID Generators
        if options.newid
            @newid = options.newid
        if options.newpid
            @newpid = options.newpid

        # Set coder
        coderArgs = if options.key then [options.key] else []
        if options.coder
            if Tools.isString options.coder
                coder = Reqs.coders[options.coder]
            else
                coder = Reqs.coders[options.coder.name or Reqs.default.coder]
                if options.coder.arguments
                    coderArgs = options.coder.arguments
            if not coder
                throw new Error "Unknown coder: '#{options.coder}'"
        else
            coder = Reqs.coders[Reqs.default.coder]
        @coder = new coder ...coderArgs

        # Set protocol
        protocolArgs = []
        if options.protocol
            if Tools.isString options.protocol
                protocol = Reqs.protocols[options.protocol]
            else
                protocol = Reqs.protocols[options.protocol.name or Reqs.default.protocol]
                if options.protocol.arguments
                    protocolArgs = options.protocol.arguments
            if not protocol
                throw new Error "Unknown protocol: '#{options.protocol}'"
        else
            protocol = Reqs.protocols[Reqs.default.protocol]
        @protocol = new protocol ...protocolArgs

        # Processing session options
        if options.session
            # Save custom arguments names
            sArgs = options.session.arguments
            if Tools.isString sArgs
                @options.session.arguments = [sArgs]
            else if Tools.isArray sArgs
                @options.session.arguments = sArgs
        else
            @options.session =
                arguments: []

        Object.defineProperty @, 'async', {
            get: => @_async
            set: (value) => @asyncSet value
        }

        @async =
            if Tools.isBoolean options.mode
            then options.mode is 'async'
            else Reqs.default.mode is 'async'


    # #################### #
    # --- Main methods --- #
    # #################### #

    ###
    Parse the request data.
    @param {string} request — the string/buffer/whatever from client/server
    (allow to transfer any user data from data input point to API functions)
    @return {object} result — result of API call (can be undefined or null)
    ###
    parse: (data) ->
        try
            decodedData = @coder.decode data
        catch e
            return @err400 "Data processing error: #{e.message}\n#{e.stack}"

        try
            if Tools.isArray decodedData
                result = @processRequest request for request in decodedData
            else
                result = @processRequest decodedData
        catch e
            return @err400 "Request parsing error: #{e.message}\n#{e.stack}"
        result

    processRequest: (data) ->
        request = @protocol.parse data
        protocol = @protocol
        types = protocol.types
        id = request.id
        switch request.type

            # ##################################################
            # API Method handling
            when types.method
                method = request.method
                xt = @events[method]
                if xt
                    args = argsConvertId2Cb @, request.args, request.cbs
                    if id       # This request was created with promise (async mode)
                        try         # Normal processing
                            result = xt.apply @, args

                            if result instanceof Promise
                                result.then( (promiseResult) =>
                                    @request new protocol.Resolve id, promiseResult
                                ).catch( (promiseErr) =>
                                    @request new protocol.Reject id, promiseErr.toString()
                                )
                                return result
                            else
                                response = new protocol.Resolve id, result

                        catch e     # Errors processing
                            response = new protocol.Reject id, e.toString()
                        return @request response
                    else        # Client/server don't want result (or, callbacks is used) (sync mode)
                        return xt.apply @, args
                else
                    return @err404 "Method not found: <#{method}>."

            # ##################################################
            # Callback handling
            when types.callback
                xt = @_callbacks[id]
                if xt is undefined
                    return @err404 "Wrong callback ID: <#{id}>."
                delete @_callbacks[id]
                args = argsConvertId2Cb @, request.args, request.cbs
                return xt.apply @, args or []

            when types.resolve
                promiseXt = @_promises[id]
                delete @_promises[id]
                if promiseXt and promiseXt.resolve
                    return promiseXt.resolve.call @, request.resolve
                else
                    return @err404 "Wrong resolve promise ID: <#{id}>."

            when types.reject
                promiseXt = @_promises[id]
                delete @_promises[id]
                if promiseXt and promiseXt.reject
                    return promiseXt.reject.call @, request.reject
                else
                    return @err404 "Wrong reject promise ID: <#{id}>."

            when types.info
                if id
                    # TODO: add full details sending
                    return @request new protocol.Callback id, [
                        Object.keys @methods    # -> events for connected client
                        Object.keys @events     # -> methods for connected client
                    ]

            when types.error
                return @err422 "Error request. Code: '#{request.code}'. #{request.message}"

            else
                return @err422 "Unknown request type: '#{request.type}'."

        return null

    ###
    Encode and send request
    @param {object} request — request object
    ###
    request: (request) ->
        @send @coder.encode request

    ###
    Send compiled request to server/client.
    @param {string} data — data for sending (default: JSON string)
    ###
    send: console.info


    # ############################## #
    # --- Error handling methods --- #
    # ############################## #


    ###
    Error 'Input data decoding error or wrong input data'
    @param {string} message — error message
    ###
    err400: (message) ->
        @error message, 400


    ###
    Error 'API Method or callback not found'
    @param {string} message — error message
    ###
    err404: (message) ->
        @error message, 404


    ###
    Error 'Wrong data input'
    @param {string} message — error message
    ###
    err422: (message) ->
        @error message, 422


    ###
    Error rised during processing request
    @param {number} code — error code
    @param {string} message — error message
    ###
    error: (message, code) ->
        console.warn code, message

    ###
    Send error message to client/server
    @param {string} id — request id
    @param {number} code — error code
    @param {string} message — error message
    ###
    sendError: (message, code, id) ->
        @request new @protocol.Error message, code, id


    # ########################## #
    # --- Options in runtime --- #
    # ########################## #
    ###
    Set method's executing mode: async or sync
    @param {boolean} value — async or sync mode
    ###
    asyncSet: (value) ->
        @_async = value
        @methodApply = if value then @methodAsyncApply else @methodSyncApply
        return
    ###
    Set coder by name
    @param {string} coder — coder name
    ###
    coderSet: (coder) -> @coder = Reqs.coders[coder]

    ###
    Set protocol by name
    @param {string} protocol — protocol name
    ###
    protocolSet: (protocol) -> @protocol = Reqs.protocols[protocol]

    ###
    Use module
    @param {Class} module — module to use
    ###
    use: (module, ...args) -> @[module.option] = new module ...args

    # ###################################### #
    # --- Callbacks arguments converters --- #
    # ###################################### #
    argsConvertCb2Id = (api, requestArgs = []) ->
        args = []
        cbs = []
        for arg, i in requestArgs           # Converting object to array
            if Tools.isFunction arg
                arg = api.addCallback arg
                cbs.push Number.parseInt i  # For array-like objects 'arguments' case
            args.push arg
        if cbs.length is 0
            cbs = null
        [args, cbs]

    argsConvertId2Cb = (api, args = [], cbs) ->
        if cbs is undefined or cbs.length is 0
            return args
        for id in cbs       # Converting object to array
            callbackId = args[id]
            args[id] = api.createCallback callbackId
        args


    # ################################## #
    # --- Callbacks handling methods --- #
    # ################################## #
    ###
    Create callback function with cached ID and session and return it.
    @param {string} id — ID of callback
    @return {function} xt — function with cached id and current Reqs API session
    ###
    createCallback: (id) ->
        api = @
        newCb = ->
            callbackRequest api, id, arguments
        newCb.created = Date.now()                              # Callback creation time - required for callbacks dispose in runtime
        newCb

    callbackRequest = (api, id, cbArgs) ->
        [args, cbs] = argsConvertCb2Id api, cbArgs
        api.request new api.protocol.Callback id, args, cbs     # Request sending

    ###
    Generate new ID for callback or promise.
    @return {string} id — callback ID as string
    ###
    newid: ->
        if @_id is Number.MAX_SAFE_INTEGER
            @_id = 0
        (++@_id).toString()

    ###
    Generate new promise ID for async request.
    @return {string} id — promise ID as string
    ###
    newpid: ->
        if @_pid is Number.MAX_SAFE_INTEGER
            @_pid = 0
        (++@_pid).toString()

    ###
    Add callback and return it's ID. By default ID is a simple counter.
    Callbacks starts from 1 and up to Number.MAX_SAFE_INTEGER.
    Transfers as a string for case if server/client can have
    Number.MAX_SAFE_INTEGER less, then client/server and custom ID generators.
    @param {function} cb — callback function
    @return {string} id — callback's ID
    ###
    addCallback: (cb) ->
        id = @newid()
        @_callbacks[id] = cb
        id

    ###
    Call method with next arguments.
    Mode (async/sync) depends on this.async flag.
    @param {string} method — method name
    @param {object} ...args — arguments
    ###
    method: (method, ...args) -> @methodApply method, args

    ###
    Call method asynchronously with next arguments
    @param {string} method — method name
    @param {object} ...args — arguments
    ###
    methodAsync: (method, ...args) -> @methodAsyncApply method, args

    ###
    Call method synchronously with next arguments
    @param {string} method — method name
    @param {object} ...args — arguments
    ###
    methodSync: (method, ...args) -> @methodSyncApply method, args

    ###
    Apply method asynchronously with arguments
    @param {string} method — method name
    @param {arrayLike} args — arguments array-like object (arguments)
    @param {array} args — arguments array
    ###
    methodAsyncApply: (method, args) ->
        [convertedArgs, cbs] = argsConvertCb2Id @, args
        pid = @newpid()
        promise = new Promise (resolve, reject) => @_promises[pid] = { resolve, reject }
        @request new @protocol.Method method, pid, convertedArgs, cbs   # Request sending
        promise

    ###
    Apply method synchronously with arguments
    @param {string} method — method name
    @param {arrayLike} args — arguments array-like object (arguments)
    @param {array} args — arguments array
    ###
    methodSyncApply: (method, args) ->
        [convertedArgs, cbs] = argsConvertCb2Id @, args
        @request new @protocol.Method method, null, convertedArgs, cbs   # Request sending

    ###
    Create function-wrapper for API calls.
    Usefull for data preprocessing before send.
    Arguments of xt will be sended to client/server directly.
    Session and method's name is cahced.
    @param {string} method — method's name, will be cached
    @return {object} this
    ###
    addMethod: (method) ->
        api = @
        @methods[method] = -> api.methodApply method, arguments
        @

    ###
    Create function-wrapper for API calls for selected function.
    Allow to prepare arguments or callback for server.
    Session and name is cahced.
    @param {string} functionName — function name, will be cached
    @param {function} xt — function, will be called before request sending
    @param {function} xtThen — function, attached to promise via 'then' method
    @param {function} xtCatch — function, attached to promise via 'catch' method
    @return {object} this
    ###
    createMethod: (method, xt, mode, xtThen, xtCatch, safe = true) ->
        api = @
        methods = @methods
        if safe and methods[method] then return
        if mode is undefined
            if xt
                methods[method] = -> api.methodApply method, xt.apply api, arguments
            else
                methods[method] = -> api.methodApply method, arguments
        else if mode is 'async'
            if xtThen and xtCatch
                mxt =
                    if xt then ->
                        api.methodAsyncApply(
                            method, xt.apply api, arguments
                        ).then( xtThen ).catch xtCatch
                    else ->
                        api.methodAsyncApply(
                            method, arguments
                        ).then( xtThen ).catch xtCatch
            else if xtThen
                mxt =
                    if xt then ->
                        api.methodAsyncApply(
                            method, xt.apply api, arguments
                        ).then xtThen
                    else ->
                        api.methodAsyncApply(
                            method, arguments
                        ).then xtThen
            else if xtCatch
                mxt =
                    if xt then ->
                        api.methodAsyncApply(
                            method, xt.apply api, arguments
                        ).catch xtCatch
                    else ->
                        api.methodAsyncApply(
                            method, arguments
                        ).catch xtCatch
            else
                mxt =
                    if xt then -> api.methodAsyncApply method, xt.apply api, arguments
                    else -> api.methodAsyncApply method, arguments
            methods[method] = mxt
        else
            methods[method] =
                if xt then -> api.methodSyncApply method, xt.apply api, arguments
                else -> api.methodSyncApply method, arguments
        @

    ###
    Create API methods. Basically just wrap function into another function
    with cached context (API instance or session) and method name.
    @param {array} methodsList — string array with function names
    @param {object} methodsList — object with functions for data preprocessing
    @param {safe} safe — do not overwrite existsing methods (true by default)
    @return {object} this
    ###
    addMethods: (methodsList, safe) ->
        methods = @methods
        if Tools.isArray methodsList

            for method in methodsList
                if Tools.isString method
                    if methods[method]
                        continue
                    @addMethod method
                else if Tools.isObject method
                    for own name, m of method
                        if methods[name] then continue
                        if Tools.isFunction m
                            @createMethod name, m, null, null, null, safe
                        else
                            @createMethod name, m.method, m.mode, m.then, m.catch, safe

        else if Tools.isObject methodsList
            for own name, m of methodsList
                if methods[name] then continue
                if Tools.isFunction m
                    @createMethod name, m, null, null, null, safe
                else
                    @createMethod name, m.method, m.mode, m.then, m.catch, safe
        @


    ###
    Get info about server's API
    @param {string} [methodName] — methodName
    @param {function} cb — callback for result processing
    @return {object}
    ###
    info: (cb, options = {}) ->
        if not Tools.isFunction cb
            throw new Error 'Reqs.info() call without callback for data.'
        # @request INFO: methodName, CB: @addCallback cb
        id = @addCallback cb
        @request new @protocol.Info id, options.events, options.methods


    ###
    Collect server's API methods list and create local client API methods
    @param {function} cb — callback
    @return {object} this
    ###
    build: (cb) ->
        @info (events, methods) =>
            @addMethods methods
            if Tools.isFunction cb
                cb events, methods
        @


    # ########################## #
    # --- Modules management --- #
    # ########################## #
    @addModule: (m) ->
        modulesContainer = @[m.category]
        if not modulesContainer
            modulesContainer = @[m.category] = Tools.null()
        modulesContainer[m.name] = m
        m

    # ########################### #
    # --- Sessions management --- #
    # ########################### #

    ###
    Create new session (child for current Reqs API)
    @param {object} [context][arg_1...arg_n] — user-defined argument
    or arguments for adding to session object as properties.
    If options.session.arguments is empty, then first argument will be
    saved to <Session>.context property.
    If options.session.arguments array is defined, then will be used
    this list of arguments names for defining the properties of session.
    @return {Session} session — session instance nested from Reqs API instance.
    ###
    new: ->
        # Check for correct session creation: session must be
        # inherited from Reqs API instance, not from session.
        if @isSession
            throw new Error '<Reqs.Session instance>.new() used for new session creation. Use insted "<Reqs instance>.new()".'

        # Creating of session instance nested from current Reqs API
        session = Object.create @

        # Adding user-defined properties
        if arguments.length > 0
            session[prop] = arguments[i] for prop, i in @options.session.arguments

        # Setting session properties
        session.isSession = true                        # Is this object is session
        session.created = Date.now()                    # Session creation date
        session.reqs = @                                # Parent Reqs API instance
        session._callbacks = Tools.null()               # This session callbacks list
        session._id = 0                                 # Callbacks ID counter
        session._promises = Tools.null()
        session._pid = 0
        session.methods = Tools.null()                  # Session client API functions
        session.addMethods @options.methods             # Methods creation (required for caching session)

        session

module.exports = Reqs
