class WS
    constructor: (options) ->
        secure = options.secure or false
        host = options.host or 'localhost'
        port = options.port or 10000
        path = options.path or ''
        secure = if secure then 's' else ''
        fullHost = 'ws' + secure + '://' + host + ':' + port + '/' + path
        sock = new WebSocket( fullHost )
        sock.onopen = options.open or noop
        sock.onmessage = options.msg or noop
        sock.onerror = options.error or noop
        sock.onclose = options.close or noop
        sock
        return sock