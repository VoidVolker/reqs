// Generated by CoffeeScript 1.10.0
var WS;

WS = (function() {
  function WS(options) {
    var fullHost, host, path, port, secure, sock;
    secure = options.secure || false;
    host = options.host || 'localhost';
    port = options.port || 10000;
    path = options.path || '';
    secure = secure ? 's' : '';
    fullHost = 'ws' + secure + '://' + host + ':' + port + '/' + path;
    sock = new WebSocket(fullHost);
    sock.onopen = options.open || noop;
    sock.onmessage = options.msg || noop;
    sock.onerror = options.error || noop;
    sock.onclose = options.close || noop;
    sock;
    return sock;
  }

  return WS;

})();

//# sourceMappingURL=ws.js.map
