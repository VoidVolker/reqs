class Main

    ###################################################################################################
    createApi = ->
        new Reqs
            send: (d) -> # Function for sending data
                if APP.WS.readyState is 1
                    APP.WS.send d
                return
            server:
                screen: ->
                    if @cb
                        @cb window.outerWidth, window.outerHeight
                    return
            client: # this - is connection; in this case client is object - it allow to create additional wrap function
                ping: (pingxt) -> # pingxt - is function for sending data to server
                    pingxt Date.now(), (ping1, time) ->
                        ping2 = Date.now()-time
                        console.log 'ping to server:', ping1, '/ ping from server:', ping2, '/ total:', ping1 + ping2
                        return
                    return

    ###################################################################################################
    # WebSockets

    connect = (obj) ->
        # console.log 'Connecting...'
        reconnectTimer = null
        new WS
            # host: '192.168.1.190'
            host: 'localhost'
            port: 10001
            open:  (e) ->
                obj.WS = this
                # console.log 'Connected'
                API.build()
                return
            msg:   (e) ->
                API.parse e.data
                return
            error: (e) ->
                # console.error 'Server connection error', e
                return
            close: (e) ->
                if reconnectTimer then clearInterval reconnectTimer
                reconnectTimer = setTimeout(
                    -> connect obj
                    3000
                )
                return

    ###################################################################################################
    constructor: ->
        window.API = createApi()
        connect APP
        console.log 'Welcome to Reqs example!\nType:\n    API.client.ping()\nOr:\n    API.client.callScreen()\nThen check server console messages and Network:ws tab in browser to see details. Library in develop and this just basic example.'

    $ Main