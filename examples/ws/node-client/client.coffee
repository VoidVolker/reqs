ws = require 'nodejs-websocket'
Reqs = require '../../../dist/node/index.js'

port = 3001
host = 'localhost'
url = "ws://#{host}:#{port}"

api = new Reqs(
    events:
        pong: (t1, time) ->
            t2 = Date.now()-time
            console.log "Event: 'Pong'. Ping #{t1} + #{t2} = #{t1 + t2}"
        message: (channel, author, msg) =>
            # console.log "New message: <##{channel} [#{author}]: #{msg}>"
            app.message channel, author, msg
        channelCreated: (channel, history) ->
            app.addChannel channel, history
    methods:
        [
            cbPing: ->
                [
                    Date.now()
                    (t1, time) ->
                        t2 = Date.now()-time
                        console.log "Ping with callback result: ping #{t1} + #{t2} = #{t1 + t2}"
                ]
            syncPing:
                method: -> [ Date.now() ] # Return array with arguments for method. Return result of 'send' function
            asyncPing:
                mode: 'async'
                method: -> [ Date.now() ] # Return array with arguments for method. Return promise.
                # Optional function for promise.then() method
                then: (result) ->
                    t1 = result[0]
                    time = result[1]
                    t2 = Date.now()-time
                    console.log "asyncPing result: #{t1} + #{t2} = #{t1 + t2}"
                # Optional function for promise.catch() method
                catch: (err) ->
                    console.error 'asyncPing error:', err
            history: ->
                [
                    (channels) ->
                        app.setHistory channels
                ]
            'message'
            'createChannel'
        ]
    send: (data) -> # Function for sending data
        console.log '==> SEND:', data
        if @conn and @conn.readyState is 1
            @conn.sendText data
        return

    session:
        arguments: 'conn'
    # coder:
    #     name: 'Coder'
    #     arguments: ['example key']
    key: 'example key'
    mode: 'sync'    # Methods call mode for all methods whithout async/sync flag
)

wsc = ws.connect( url, ->
    console.log "--- Connected to : #{url} ---"
    conn = @
    # Create new ReqsAPI session
    conn.session = api.new conn

    # Connection closing log
    conn.on 'close', (code, reason) ->
        console.log '--- Connection closed', code, reason
        delete conn.session
        return

    # Conection errors handling (necessarily!)
    conn.on 'error', (err) ->
        # This error happens when connections lost
        if err.code is 'ECONNRESET'
            # console.error('--- Connection close error ECONNRESET');
        else
            console.error '--- Connection error: ', err
        return

    # WS messages processing
    conn.on 'text', (text) ->
        console.log '<== Incoming request:', text
        @session.parse text

    conn.session.methods.cbPing()
    conn.session.methods.syncPing()
    conn.session.methods.asyncPing()
)
