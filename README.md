[![Join the chat at https://gitter.im/VoidVolker/reqs](https://badges.gitter.im/VoidVolker/reqs.svg)](https://gitter.im/VoidVolker/reqs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Reqs

JSON interface library for HTTP, Web Sockets, Sockets and any other interfaces.

Install:

    npm install node-reqs

Server code:

```JavaScript
var Reqs = require('../../reqs.js');

var api = new Reqs({
    server: {
        // this = {
        //     reqs: <reqs instance>
        //     conn: <connection object>
        //     [cb: <callback>]
        // }
        ping: function(time){
            var t1 = time ? Date.now()-time : 0 ;
            console.log('ping from client:', t1);
            if( this.cb ){
                this.cb(t1, Date.now());
            }
        },
        callScreen: function(){ // Emulate server call of client server API from client
            var conn = this.conn;
            api.client.screen.call(conn, function(w, h){
                console.log('Retrieve screen size from client:', w, h);
            });
        }
    }
    , client: ['screen'] // Client server API list
    , send: function(data){
        this.sendText(data);
    }
    , isValid: 'secret'
});

function rootHandle(str) {
    try{
        console.info('    parsing string:', str);
        api.parse(str, this); // this - is connection object
    } catch(e){
        console.log('Reqs error: ', e);
    }
}

exports.root = rootHandle;
```

Each request from client can be validated via option `isValid`.

If `isValid` is string: search it in request property `validation`

If `isValid` is function: execute it and check returned value. If `true` - request is valid, in other case - not valid and call function `invalid`.

Example:

```
function isValid(o){
    if( o.hasOwnProperty('validation') ){
        return o.validation === isValid;
    } else {
        return false;
    }
};
```

And client:

```JavaScript
var api = new new Reqs({
    validate: 'secret', // Simple request validation via secret toket
    send: function(d) {
        if (APP.WS.readyState === 1) {
            APP.WS.send(d);
        }
    },
    server: {
        screen: function() {
            if (this.cb) {
                this.cb(window.outerWidth, window.outerHeight);
            }
        }
    },
    client: {
        ping: function(pingxt) {
            pingxt(Date.now(), function(ping1, time) {
                var ping2;
                ping2 = Date.now() - time;
                console.log(
                    'ping to server:', ping1,
                    '/ ping from server:', ping2,
                    '/ total:', ping1 + ping2
                );
            });
        }
    }
});
```

Each request to server can be validated via option `validate`.

If `validate` is string: add property `validation` in request with this value

If `validate` is function: execute it with request object and send returned value as request object.

Example:

```
function validate(o){
    o.validation = validate;
    return o;
};

```

## Develop

Module contain `dev` directory with simple example of `client <-> server` interface via WebSockets. `dev` - is simple submodule with all dependencies to develop and build library.

Install node-inspector to debug server code from browser:

    npm install -g node-inspector

You can use any other debug tool you like. You can configure it in [nano-watcher](https://github.com/VoidVolker/nano-watcher) config file `dev/nano-watcher.json`.

Next you need install dev dependecies:

    cd ./dev
    npm install

To build library:

    npm run build

To watch files and automatically rebuild library and restart server:

    npm run watch
