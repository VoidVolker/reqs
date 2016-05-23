class Main

    ###################################################################################################
    # API
    apiList =
        test: (a, b) ->
            console.log('Test return from server:', a, b);
            return

    createApi = ->
        new API (d) ->
            if APP.WS.readyState is 1
                APP.WS.send d
            return
        , apiList

    ###################################################################################################
    # WebSockets

    connect = (obj) ->
        console.log 'Connecting...'
        reconnectTimer = null
        new WS
            # host: '192.168.1.190'
            host: 'localhost'
            port: 10001
            open:  (e) ->
                obj.WS = this
                console.log 'Connected'
                return
            msg:   (e) ->
                APP.API.parse e.data
                return
            error: (e) ->
                # console.error 'Server connection error', e
                return
            close: (e) ->
                if reconnectTimer then clearInterval reconnectTimer
                reconnectTimer = setTimeout(
                    -> connect(obj)
                    3000
                )
                return

    ###################################################################################################
    constructor: ->
        `$window = $(window); $body = $(window.body)`
        APP.API = api = createApi()
        connect APP

    $ Main