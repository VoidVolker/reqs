class JRPCRequest
    constructor: (id) ->
        if id then @id = id
        @jsonrpc = '2.0'

class JRPCMethod extends JRPCRequest
    constructor: (@method, id, @params = [], cbs) ->
        super id
        if cbs then @cbs = cbs


class JRPCCallback extends JRPCRequest
    constructor: (@id, @params = [], cbs) ->
        super id
        if cbs then @cbs = cbs

class JRPCError extends JRPCRequest
    constructor: (code, message, id) ->
        super id
        # @result = null
        @error = code: code, message: message

class JRPCInfo extends JRPCRequest
    constructor: (@id, server, client) ->
        super id
        if server then @server = server
        if client then @client = client


class JRPCProtocol extends Protocol

    Method:     JRPCMethod
    Callback:   JRPCCallback
    Error:      JRPCError
    Info:       JRPCInfo

    # Response processing
    constructor: ->
        super()
        methodsInfo =
            type: 'Array'
            value:
                type: ['Object', 'String']
                props:
                    name: Model.required 'String'
                    info: Model.required 'String'
                    args:
                        type: 'Array'
                        value:
                            type: 'Object'
                            props:
                                name: Model.required 'String'
                                type: Model.required 'String'
                                info: Model.required 'String'
                    ret: 'String'

        @model =
            method: new Model @,
                method: Model.required 'String'
                params: Model.required 'Array'
                id: 'String'
                cbs: 'Array'
            callback: new Model @,
                result: Model.required 'Array'
                id: 'String'
                cbs: 'Array'
            error: new Model @,
                error:
                    type: Model.required 'Object'
                    props:
                        code: Model.required 'Number'
                        message: Model.required 'String'
                id: 'String'
            info: new Model @,
                id: Model.required 'String'
                server: methodsInfo
                client: methodsInfo

    # Response processing
    parse: (request) ->
        super()

        id = if request.id then request.id.toString() else null

        if request.method
            @model.method.validate @, request
            new Protocol.Method request.method, id, request.params, request.cbs

        else if request.error
            @model.error.validate @, request
            new Protocol.Error err.message, err.code, id

        else if request.result
            @model.callback.validate @, request
            new Protocol.Callback id, request.result, request.cbs

        # Reqs custom property (?)
        else if request.info
            @model.info.validate @, request
            new Protocol.Info id, request.server, request.client

        else
            @throw "Unknown request: '#{JSON.stringify(request)}'"

module.exports = JRPCProtocol
