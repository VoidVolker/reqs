class Server

    constructor: ->

    init: (app) ->
        @channels = channels =
            general:
                history: [
                    author: 'Welcome'
                    message: 'Welcome to #general channel'
                ]

        @api = new Reqs(
            events:
                syncPing: (time) ->
                    now = Date.now()
                    @methods.pong now-time, now
                asyncPing: (time) ->
                    now = Date.now()
                    # throw new Error 'Some error'
                    return [now-time, now]
                message: (channel, author, message) ->
                    c = channels[channel]
                    if c
                        c.history.push(
                            author: author
                            message: message
                        )
                        @methods.message channel, author, message
                createChannel: (channel) ->
                    c = channels[channel]
                    if c
                        @sendError 'Channel already exists', 422, 'test id'
                    else
                        history = [
                            author: 'Welcome'
                            message: "Welcome to ##{channel} channel"
                        ]
                        channels[channel] = { history }
                        @methods.channelCreated channel, history
                history: (cb) ->
                    if cb
                        cb channels
                channelHistory: (channel, cb) ->
                    c = channels[channel]
                    if c and cb
                        cb c.history
            methods: ['pong', 'message', 'channelCreated']
            send: (data) ->
                console.log '<== RECEIVE local:', data
                app.api.parse data
                return

            # coder:
            #     name: 'Coder'
            #     arguments: ['example key']
            key: 'example key'
            mode: 'sync' # By default all methods are sync
        )


class App

    constructor: (@$) ->
        @server = 'local'
        @channels = {}

        @$.send.click (e) =>
            msg = @$.textbox.val()
            if msg.length is 0
                return
            @api.methods.message @selectedChannel, @$.nickname.val(), msg
            @$.textbox.val ''

        @$.createChannel.click (e) =>
            name = @$.channelName.val()
            if name.length is 0
                return
            @api.methods.createChannel name
            @$.channelName.val ''

        @$.server.change (e) =>
            @server = @$.server.val()
            if @server is 'ws'
                @wsConnect()
            else
                @connect()

    init: (srv) ->
        app = @
        @api = new Reqs(
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
                    longMethodA:
                        mode: 'async'
                        method: ->
                            console.log 'Long method A started'
                            []
                        then: (result) -> console.log 'Long method A result:', result
                        catch: (err) -> console.error 'Long method A error:', err
                    longMethodB: ->
                        console.log 'Long method B started'
                        [
                            (result) ->
                                console.log 'Long method B result:', result
                        ]

                    # Example use:
                    # app.api.methods.asyncPing()
                    #   .then(function(result) {
                    #       var t1 = result[0], time = result[1], t2 = Date.now()-time;
                    #       console.log(`asyncPing result: ${t1} + ${t2} = ${t1 + t2}`);
                    #   }).catch(function(err) { console.error('asyncPing error:', err) })

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
                if app.server is 'ws'
                    # Send data via WebSockets
                    if app.ws and app.ws.readyState is 1
                        app.ws.send data
                else if app.server is 'local'
                    # Send data to local server
                    srv.api.parse data
                return
            # coder:
            #     name: 'Coder'
            #     arguments: ['example key']
            key: 'example key'
            mode: 'sync'    # Methods call mode for all methods whithout async/sync flag
        )

        srv.init @
        @connect()
        @

    connect: ->
        @api.methods.history()
        @

    addChannel: (channel, history = []) ->
        if @channels[channel] then return
        @channels[channel] = history: history
        $c = $ "<div class='channel'>##{channel}</div>"
        $c.click (e) => @selectChannel channel
        @$.channels.append $c
        @

    setHistory: (channels) ->
        @$.channels.empty()
        @channels = {}
        @selectedChannel = null
        for own name, c of channels
            @addChannel name, c.history
            if @selectedChannel is null
                @selectChannel name
        @

    selectChannel: (channel) ->
        @selectedChannel = channel
        @$.messages.empty()
        c = @channels[channel]
        msgs = []
        for m in c.history
            msgs.push @createMessage m.author, m.message
        @$.messages.html msgs
        @

    createMessage: (author, message) ->
        $ "<div class='message'>[<span class='author'>#{author}</span>]: <span class='text'>#{message}</span></div>"

    message: (channel, author, message) ->
        if not @channels[channel]
            @addChannel channel
        @channels[channel].history.push(
            author: author
            message: message
        )

        if @selectedChannel is channel
            @$.messages.append @createMessage author, message
        @

    wsConnect: ->
        app = @
        port = 3001
        console.log 'Connecting to WebSockets: ', port
        if @ws
            @ws.close()
        @ws = new WS
            host: 'localhost'
            port: port
            open:  (e) ->
                console.log 'WS Connected to:', port
                app.connect()
                return
            msg:   (e) ->
                console.log '<== RECEIVE ws:', e.data
                app.api.parse e.data
                return
            error: (e) ->
                console.error 'WS connection error', e
                return
            close: (e) ->
                delete app.session
                return



$ ->
    srv = window.SRV = new Server
    window.APP = new App(
        channels: $ '.channels'
        messages: $ '.messages'
        textbox: $ '.textbox'
        send: $ '.send'
        nickname: $ '.nickname'
        channelName: $ '.channelName'
        createChannel: $ '.createChannel'
        server: $ '.server'
        useHttpApi: $ '#useHttpApi'
    ).init srv




# r = new Reqs(

#     send:
#         ws: (data) ->
#         ajax: (data) ->
# )