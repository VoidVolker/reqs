express = require 'express'
ws = require 'nodejs-websocket'
Reqs = require '../../../dist/node/index.js'

httpPort = 3000
wsPort = 3001
host = 'localhost'

class Server
    constructor: (send) ->
        srv = @

        @channels = channels =
            general:
                history: [
                    author: 'Welcome'
                    message: 'Welcome to #general channel'
                ]

        @api = new Reqs(
            events:
                cbPing: (time, cb) ->
                    now = Date.now()
                    # throw new Error 'cbPing example error'
                    cb now-time, now
                syncPing: (time) ->
                    now = Date.now()
                    # throw new Error 'syncPing example error'
                    @methods.pong now-time, now
                asyncPing: (time) ->
                    now = Date.now()
                    # throw new Error 'asyncPing example error'
                    return [now-time, now]
                longMethodA: ->
                    p = new Promise( (resolve, reject) ->
                        setTimeout(
                            ->
                                resolve 'Resolved A'
                            5000
                        )
                    )
                    return p
                longMethodB: (cb) ->
                    setTimeout(
                        ->
                            cb 'Resolved B'
                        5000
                    )

                message: (channel, author, message) ->
                    c = channels[channel]
                    if c
                        c.history.push(
                            author: author
                            message: message
                        )
                        # Broadcast message
                        for conn in srv.wss.connections
                            if conn.session
                                conn.session.methods.message channel, author, message
                createChannel: (channel) ->
                    c = channels[channel]
                    if c
                        @sendError 'Channel already exists', 422
                    else
                        history = [
                            author: 'Welcome'
                            message: "Welcome to ##{channel} channel"
                        ]
                        channels[channel] = { history }
                        # Broadcast message
                        for conn in srv.wss.connections
                            if conn.session
                                conn.session.methods.channelCreated channel, history
                history: (cb) ->
                    if cb
                        cb channels
                channelHistory: (channel, cb) ->
                    c = channels[channel]
                    if c and cb
                        cb c.history

            methods: ['pong', 'message', 'channelCreated']

            send: (data) ->
                conn = @conn
                if conn.readyState is conn.OPEN # Check connection state
                    console.log '==> Sending response:', data
                    conn.sendText data

            session:
                arguments: 'conn' # Or ['a', 'b', 'c']
            # coder:
            #     name: 'Coder'
            #     arguments: ['example key']
            key: 'example key'
            mode: 'sync' # By default all methods are sync
        )

        @wss = ws.createServer( (conn) ->
            console.log '--- New connection! conn.path: ' + conn.path

            # Create new ReqsAPI session
            conn.session = srv.api.new conn

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

            return
        )

        @app = express()
        @app.use express.static './examples/ws/client/'
        @app.use '/dist/web/reqs.js', express.static './dist/web/reqs.js'
        @app.listen( httpPort, ->
            console.log "Example Http server listening: http://localhost:#{httpPort}"
        )

        @wss.listen wsPort, host
        console.log "Example WS Server listening: ws://localhost:#{wsPort}"

global.SRV = new Server
