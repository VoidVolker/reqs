class API
    constructor: (sender, api) ->
        r = new Reqs
            send: sender
            SPI: api
            # CPI: ['ping']
            # SPI:
            #     ping: (time) ->
            #         time = if time then Date.now() - time else 0
            #         r.CPI.pong
            #             time: Date.now()
            #             ping: time
            #         return
            #     pong: (arg) ->
            #         console.info '/ pong: to server, from server', arg.ping, Date.now() - arg.time
            #         return
        return r
