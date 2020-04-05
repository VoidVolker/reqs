express = require 'express'
ws = require 'nodejs-websocket'
Reqs = require '../../../dist/node/index.js'

httpPort = 3000
host = 'localhost'

class Server
    constructor: ->
        srv = @
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
            methods: ['pong']

            send: (data) -> return data
            error: (message, code) -> @sendError message, code
            session:
                arguments: 'res'
            # coder:
            #     name: 'Coder'
            #     arguments: ['example key']
            key: 'example key'
            mode: 'sync' # By default all methods are sync
        )

        @app = express()
        @app.use express.static './examples/http/client/'
        @app.use '/dist/web/reqs.js', express.static './dist/web/reqs.js'
        @app.post('/api', (req, res) ->
            data = ''
            req.setEncoding 'utf8'
            req.on 'data', (chunk) -> data += chunk;
            req.on 'end', ->
                session = srv.api.new res
                console.log '<== Incoming request:', data
                result = session.parse data
                if not result
                    result = ''
                console.log '==> Sending response:', result
                res.end result
        )
        srv.app.listen(
            httpPort
            ->
                console.log "Example Http server listening: http://localhost:#{httpPort}"
        )

global.SRV = new Server
