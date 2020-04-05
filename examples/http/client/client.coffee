
class App

    constructor: (@$) ->
        @httpApiUrl = '/api'

        app = @
        @api = new Reqs(
            events:
                pong: (t1, time) ->
                    t2 = Date.now()-time
                    console.log "Event: 'Pong'. ping #{t1} + #{t2} = #{t1 + t2}"
            methods:
                [
                    cbPing: ->
                        [
                            Date.now()
                            (t1, time) ->
                                t2 = Date.now()-time
                                console.log "Ping with callback result: ping #{t1} + #{t2} = #{t1 + t2}"
                        ]
                    syncPing: -> [ Date.now() ] # Return array with arguments for method.
                    asyncPing:
                        mode: 'async'
                        method:  -> [ Date.now() ] # Return array with arguments for method (arguments array for method). Returns promise.
                        # Optional function for promise.then() method
                        then: (result) ->
                            t1 = result[0]
                            time = result[1]
                            t2 = Date.now()-time
                            console.log "asyncPing result: #{t1} + #{t2} = #{t1 + t2}"
                        # Optional function for promise.catch() method
                        catch: (err) ->
                            console.error 'asyncPing error:', err
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
                console.log '==> Request:', data
                app.apiPost data
                return

            session:
                arguments: ['ws']
            # coder:
            #     name: 'Coder'
            #     arguments: ['example key']
            key: 'example key'
            mode: 'sync'    # Methods call mode for all methods whithout async/sync flag
        )

    apiPost: (data) ->
        $.ajax(
            url: @httpApiUrl
            type: 'POST'
            data: data
            contentType: 'application/json; charset=utf-8',
            dataType: 'text'
            success: (result) =>
                console.log '<== Response:', result
                if result
                    r = @api.parse result
                else
                    console.error 'Post response is undefined'
        )

    sendAsyncPing: ->
        APP.api.methods.asyncPing().then( (result) ->
            t1 = result[0]
            time = result[1]
            t2 = Date.now()-time
            console.log "asyncPing result: #{t1} + #{t2} = #{t1 + t2}"
        ).catch( (err) ->
            console.error 'asyncPing error:', err
        )

$ -> window.APP = new App
