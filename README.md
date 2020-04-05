[![Join the chat at https://gitter.im/VoidVolker/reqs](https://badges.gitter.im/VoidVolker/reqs.svg)](https://gitter.im/VoidVolker/reqs?utm_source=badge&utm_medium=badge&utm_campaign=pr-badge&utm_content=badge)

# Reqs

JSON interface library for HTTP, Web Sockets, Sockets and any other interfaces.

Install:

    npm i node-reqs

HTTP Server code example:

```JavaScript
const Reqs = require('node-reqs')
const express = require('express')

const httpPort = 3000
const host = 'localhost'

const api = new Reqs({
    events: {
        cbPing: function(time, cb) {
            var now = Date.now()
            // throw new Error 'cbPing example error'
            return cb(now - time, now)
        },
        syncPing: function(time) {
            var now = Date.now()
            // throw new Error 'syncPing example error'
            return this.methods.pong(now - time, now)
        },
        asyncPing: function(time) {
            var now = Date.now()
            // throw new Error 'asyncPing example error'
            return [now - time, now]
        }
    },
    methods: ['pong'],
    // send function is used for sending compiled and encoded requests to client
    send: function(data) { return data },
    // error function is for processing error
    error: function(message, code) {
        // Send error to client
        return this.sendError(message, code)
    },
    // Session creation options
    session: {
        // Arguments for sessions constructor:
        //      arguments: ['arg1', 'arg2']
        // ->
        //      var session = api.new('arg1', 'arg2')   // Create new session. Session is linked to 'api' object and can use all methods available in 'api' object.
        //      session.arg1 === 'arg1'
        //      session.arg2 === 'arg2'
        arguments: ['res']
    },
    // Short key option for default coder:
    key: 'example key'
})

const app = express()

app.post('/api', function(req, res) {
    var data = ''
    req.setEncoding('utf8')
    req.on('data', function(chunk) { return data += chunk })
    req.on('end', function() {
        console.log('<== Incoming request:', data)
        var session = srv.api.new(res)
        var result = session.parse(data)
        if (!result) {
            result = ''
        }
        console.log('==> Sending response:', result)
        res.end(result)
    })
})

app.listen(httpPort, function() {
    console.log('Example Http server listening on port:', httpPort)
})

srv = new Server()
```

Http client:

```JavaScript
class App {
    constructor() {
        var app = this
        this.httpApiUrl = '/api'
        this.api = new Reqs({
            events: {
                pong: function(t1, time) {
                    var t2 = Date.now() - time
                    console.log(`Event: 'Pong'. ping ${t1} + ${t2} = ${t1 + t2}`)
                }
            },
            methods: [
                {
                    cbPing: function() {
                        return [
                            Date.now(),
                            function(t1, time) {
                                var t2 = Date.now() - time
                                console.log(`Ping with callback result: ping ${t1} + ${t2} = ${t1 + t2}`)
                            }
                        ]
                    },
                    syncPing: function() {
                        return [Date.now()] // Return array with arguments for method. Method result of 'send' function or undefined.
                    },
                    asyncPing: {
                        mode: 'async',
                        method: function() {
                            return [Date.now()] // Return array with arguments for method. Method returns promise.
                        },
                        // Optional function for promise.then() method
                        then: function(result) {
                            var t1 = result[0]
                            var time = result[1]
                            var t2 = Date.now() - time
                            console.log(`asyncPing result: ${t1} + ${t2} = ${t1 + t2}`)
                        },
                        // Optional function for promise.catch() method
                        catch: function(err) {
                            console.error('asyncPing error:', err)
                        }
                    },
                    history: function() {
                        return [
                            function(channels) {
                                app.setHistory(channels)
                            }
                        ]
                    }
                }
            ],
            send: function(data) { // Function for sending data
                console.log('==> Request:', data)
                app.apiPost(data)
            },
            key: 'example key'
        })
    }

    apiPost(data) {
        return $.ajax({
            url: this.httpApiUrl,
            type: 'POST',
            data: data,
            contentType: 'application/json; charset=utf-8',
            dataType: 'text',
            success: (result) => {
                console.log('<== Response:', result)
                if (result) {
                    this.api.parse(result)
                } else {
                    console.error('Post response is undefined')
                }
            }
        })
    }

    asyncPing() {
        APP.api.methods.asyncPing().then(function(result) {
            var t1 = result[0]
            var time = result[1]
            var t2 = Date.now() - time
            console.log(`asyncPing result: ${t1} + ${t2} = ${t1 + t2}`)
        }).catch(function(err) {
            console.error('asyncPing error:', err)
        })
    }

}

$(function() { window.APP = new App() })
```

WebSockets Server code example:

```JavaScript
const ws = require('nodejs-websocket')
const Reqs = require('node-reqs')

const wsPort = 3001
const host = 'localhost'

Server = class Server {
    constructor(send) {
        srv = this
        this.api = new Reqs({
            events: {
                cbPing: function(time, cb) {
                    var now = Date.now()
                    // throw new Error 'cbPing example error'
                    cb(now - time, now)
                },
                syncPing: function(time) {
                    var now = Date.now()
                    // throw new Error 'syncPing example error'
                    this.methods.pong(now - time, now)
                },
                asyncPing: function(time) {
                    var now = Date.now()
                    // throw new Error 'asyncPing example error'
                    return [now - time, now]
                }
            },
            methods: ['pong'],
            send: function(data) {
                if (this.conn.readyState === this.conn.OPEN) { // Check connection state
                    console.log('==> Sending response:', data)
                    this.conn.sendText(data)
                }
            },
            session: {
                arguments: 'conn'
            },
            key: 'example key',
        })

        this.wss = ws.createServer(function(conn) {
            console.log('--- New connection! conn.path: ' + conn.path)
            // Create new Reqs session with reference to WS connection
            conn.session = srv.api.new(conn)
            // Connection closing log
            conn.on('close', function(code, reason) {
                console.log('--- Connection closed', code, reason)
                delete conn.session
            })

            // Conection errors handling (necessarily!)
            conn.on('error', function(err) {
                // This error happens when connections lost
                if (err.code === 'ECONNRESET') {

                } else {
                    // console.error('--- Connection close error ECONNRESET')
                    console.error('--- Connection error: ', err)
                }
            })

            // WS messages processing
            conn.on('text', function(text) {
                console.log('<== Incoming request:', text)
                this.session.parse(text)
            })
        })

        this.wss.listen(wsPort, host)
        console.log('Example WS Server listening on port:', wsPort)
    }

}

srv = new Server()
```

WS client example:
```JavaScript
const ws = require('nodejs-websocket')
const Reqs = require('node-reqs')

const port = 3001
const host = 'localhost'
const url = `ws://${host}:${port}`

var api = new Reqs({
    events: {
        pong: function(t1, time) {
            var t2 = Date.now() - time
            console.log(`Event: 'Pong'. Ping ${t1} + ${t2} = ${t1 + t2}`)
        },
        message: (channel, author, msg) => {
            // console.log "New message: <##{channel} [#{author}]: #{msg}>"
            app.message(channel, author, msg)
        },
        channelCreated: function(channel, history) {
            app.addChannel(channel, history)
        }
    },
    methods: [
        {
            cbPing: function() {
                return [
                    Date.now(),
                    function(t1, time) {
                        var t2 = Date.now() - time
                        console.log(`Ping with callback result: ping ${t1} + ${t2} = ${t1 + t2}`)
                    }
                ]
            },
            syncPing: {
                method: function() {
                    return [Date.now()] // Return array with arguments for method. Method returns result of 'send' function
                }
            },
            asyncPing: {
                mode: 'async',
                method: function() {
                    return [Date.now()] // Return array with arguments for method. Returns promise.
                },
                // Optional function for promise.then() method
                then: function(result) {
                    var t1 = result[0]
                    var time = result[1]
                    var t2 = Date.now() - time
                    console.log(`asyncPing result: ${t1} + ${t2} = ${t1 + t2}`)
                },
                // Optional function for promise.catch() method
                catch: function(err) {
                    console.error('asyncPing error:', err)
                }
            },
            history: function() {
                return [
                    function(channels) {
                        app.setHistory(channels)
                    }
                ];
            }
        },
        'message',
        'createChannel'
    ],
    send: function(data) { // Function for sending data
        console.log('==> SEND:', data)
        if (this.conn && this.conn.readyState === 1) {
            this.conn.sendText(data)
        }
    },
    session: {
        arguments: 'conn'
    },
    key: 'example key',
    mode: 'sync' // Methods call mode for all methods whithout async/sync flag
});

var wsc = ws.connect(url, function() {
    console.log(`--- Connected to : ${url} ---`);
    var conn = this
    // Create new Reqs session
    conn.session = api.new(conn)
    // Connection closing log
    conn.on('close', function(code, reason) {
        console.log('--- Connection closed', code, reason)
        delete conn.session
    });
    // Conection errors handling (necessarily!)
    conn.on('error', function(err) {
        // This error happens when connections lost
        if (err.code === 'ECONNRESET') {

        } else {
            // console.error('--- Connection close error ECONNRESET');
            console.error('--- Connection error: ', err)
        }
    });
    // WS messages processing
    conn.on('text', function(text) {
        console.log('<== Incoming request:', text)
        this.session.parse(text)
    });

    conn.session.methods.cbPing()
    conn.session.methods.syncPing()
    conn.session.methods.asyncPing()
});
```

Full examples can be found in `examples` dir.

---

# Documentation

## Base logic

`this` - is Reqs instance.

Method call:

    this.method('method_name')
    |
    V
    request = new this.protocol.Method('method_name', 'id', args_array, cbs_array)
    |
    V
    data = this.coder.encode(request)
    |
    V
    this.send(data)

Next - transport level (WebSockets, Http or whatever).
Request processing:

    request = this.coder.decode(data)
    |
    V
    parsed = this.protocol.parse(request)
    |
    V
    this.processRequest(parsed)
    |
    V
    (a) 'method'    this.events['method_name'].apply(this, args_array)
    (b) 'callback'  this.callbacks['id'].apply(this, args_array)
    (c) 'resolve'   this.promises[id].resolve.call(this, args_array)
    (d) 'reject'    this.promises[id].reject.call(this, args_array)
    (e) 'info'      this.request new protocol.Callback(id, [this_events_info, this_methods_info])
    (f) 'error'     this.error('message', code, request_id)

## Examples run

    npm i node-reqs --save-dev
    cd ./node_modules/node-reqs/

    node --inspect ./examples/ws/server/server.js
    node --inspect ./examples/ws/node-client/client.js
    node --inspect ./examples/http/server/server.js

## API instance creation

```JavaScript
var api = new Reqs(options)
```

| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| options | Object | API options with handlers | |

Create new Reqs instance. Instance provides Reqs methods for calling user-defined API methods and processing API events.

## Options

| Option | Type | Description |
| --- | --- | --- |
| [events](#events) | Object | Functions - event handlers |
| [methods](#methods) | Object -> Function \| Object<br>Array -> String<br>Array -> Object \| String | Functions - arguments preprocessing<br> Object - methods options<br>String - methods names
| [send](#send) | Function | Function for sending raw data |
| [error](#error) | Function | Function for errors processing in events or methods functions |
| [coder](#coder) | String<br>Object | Coder name to use<br>Coder options |
| [key](#key) | String | Default coder option `key` (shortcut) |
| [protocol](#protocol) | String<br>Object | Protocol name to use<br>Protocol options |
| [session](#session) | Object | Session options |
| [newid](#newid) | Function | Callbacks ID generator |
| [newpid](#newpid) | Function | Promises ID generator |


### `events`

| Method mode | Event handler return value type | Description | When to use |
| --- | --- | --- | --- |
| `sync` | - | In sync mode return value is ignored | If you don't want to use promise or you have simple synchronous code everywhere |
| `async` | Any, not `Promise` | Synchronous code in event whithout promise | When method caller want to use promise |
| `async` | `Promise` | Asynchronous code in event handler or operation required some time (DB Acces, for example) | Asynchronous code everywhere |

Anyway, test all variants and select most comfortable mode for your case.

Default event for method in 'sync' (default) mode:
```JavaScript
events: {
    eventName: function(arg1, argN) { }
}
```
Option `events` contains functions, which will be executed, when connected client calls methods (`clientApi.methods.cbPing()`, for example). Method's arguments can be standard JS objects and callbacks. All other objects types not supported by default coder (JSON.stringify).
For example, method call:
```JavaScript
clientApi.method('cbPing', Date.now(), function(t1, time) { })
```
And event will have next arguments:
```JavaScript
cbPing: function(time, cb) { }
```

Event for method in async mode with promise as result:
```JavaScript
events: {
    eventName: function(arg1, argN) {
        var promise = new Promise(function(resolve, reject) {

        })
        return promise
    }
}
```
If event returns promise - then Reqs attach handlers to `promise.then` and `promise.catch` for later data processing and sending response to connected client or server. If event throw error: Reqs will send reject type request immediatly and on other side promise will be rejected.

Event for method in async mode with result and error throw:
```JavaScript
events: {
    eventName: function(arg1, argN) {
        var result = 'some result'
        var someError = false
        if (someError) {
            throw new Error('Some error')
        }
        return result
    }
}
```
If event returns not promise: Reqs will send resolve type request and on other side promise will be resolved. If event throw error: Reqs will send reject type request immediatly and on other side promise will be rejected.

How it works.

When method is called: Reqs check each argument type and converts callback to new generated callback ID and append to request property with callbacks positions in arguments list. Then saves original callbacks into session storage (`_callbacks` property).

Before event call: Reqs check each argument type and converts callback ID to locally created callback. This callbacks is function-wrappes with cached session and callback ID's for later sending as request.

When callback is called: send callback-type request with callback ID and own arguments list.

When callback request is returned to method's caller: Reqs finds callbacks IDs in session storage and calls with arguments from request.

Reqs doesn't validate methods arguments type or value (for now, may be later this feature will be added).

### `methods`
| Type | Value type | Description |
| --- | --- | --- |
| Array | String | Method's name |
| Array | Function | Function for arguments preprocessing |
| Array | Object | Method options |
| Object | Function | Function for arguments preprocessing |
| Object | Object | Method options |

This option creates local functions-wrappers for fast methods calls.

Method options:

| Option name | Type | Description | Is required |
| --- | --- | --- | --- |
| method | Function | Function for arguments preprocessing | - |
| mode | String -> `sync` \| `async` | Method's calling mode: return result of `send` function or return `Promise` | - |
| then | Function | Function for promise method `then`, only for mode `async` | - |
| catch | Function | Function for promise method `catch`, only for mode `async` | - |

#### Array with methods names:
```JavaScript
methods: ['methodA', 'methodB']
```
In this case methods arguments will be sended as is.

#### Object with function:
```JavaScript
methods: {
    methodA: function(arg1, argN) {
        ... // Arguments preprocessing
        return ['argA', 'argB']
    },
    methodB: function() {
        ... // Arguments preprocessing
        return ['argA', 'argB']
    }
}
```
In this case this custom functions allow to preprocess or convert data for sending. To send data function must return array with arguments.

Methods call:
```JavaScript
api.methods.methodA('arg1', 'argN')
api.methods.methodB()
```

#### Object with method's options object:
```JavaScript
methods: {
    methodA: {
        mode: 'async',
        method: function(arg1, argN) {
            ... // Arguments preprocessing
            return ['argA', 'argB']
        },
        then: function(result) {
            ...
        },
        catch: function(err) {
            ...
        }
    },
    methodB: {
        mode: 'sync'
        method: function(arg1, argN) {
            ...
            return ['argA', 'argB']
        }
    }
}
```
Method can be called in 2 variants:

1. `sync` mode. Simple call: response to call is optional. Usefull for Http api and cases, when send function can return response to call. Default mode.
1. `async` mode. Call with ID in request: in this case method returns `Promise` object. In this case on server side event must return data or throw error. And `Promise` on client side will be completed with event data or throw error. Also, options `then` and `catch` - is same as `promise.then` and `promise.catch`.

```JavaScript
var promise = api.methods.methodA('arg1', 'argN')
promise.then(function(result){ ... }).catch(function(err){ ... })

var syncResult = api.methods.methodB()
```

Default mode, can be changed in runtime: `Reqs.default.mode === 'sync'`
Mode switch in runtime:
```JavaScript
api.async = true        // mode === 'async'
api.async = false       // mode === 'sync'
```
This mode flag is affects only to methods declared whithout mode option. If method declared with mode option - flag api.async is ignored for this method.

#### Array with methods options and names:
```JavaScript
methods: [
    {
        methodA: {
            mode: 'async',
            method: function(arg1, argN) {
                ... // Arguments preprocessing
                return ['argA', 'argB']
            },
            then: function(result) {
                ...
            },
            catch: function(err) {
                ...
            }
        },
        methodB: function(arg1, argN) {
            ...
            return ['argA', 'argB']
        }
    },
    'methodA',
    'methodB'
]
```

### `send`
| Argument | Type | Description |
| --- | --- | --- |
| data | String \| Buffer \| Whatever | Data for sending via WebSockets, Http or any other transport, data source is `api.coder.encode()` function |
| return | undefined \| String \| Buffer \| Whatever | For methods in `sync` mode value, returned by send function will be returned and `api.parse` function |

```JavaScript
send: function(data) { app.apiPost(data) }
```
Function for sending data to server or to client. Have only one argument: `data` - encoded data. Can be string, buffer or whatever. Result of `this.coder.encode` function. If function returns any result - this result can be returned from `this.parse` function.

Example code from http api server:
```JavaScript
...
send: function(outData) { return outData }
...
var result = session.parse(inData)
...
```

### `error`
| Argument | Type | Description |
| --- | --- | --- |
| message | String | Error message |
| code | Number | Error code |
| return | undefined \| Whatever | For methods in `sync` mode value, returned by error function will be returned and `api.parse` function |

Server code:
```JavaScript
error: function(message, code) {
    // Send error to client
    return this.sendError(message, code)
}
```
Client code:
```JavaScript
error: function(message, code) {
    console.error('API error:', message, code)
}
```
Function for errors processing. For server side use `this.sendError(message, code)` for sending error request to client.

### `coder`
Coder - class for data encodind and decoding. Coder can use additional secure options like adding API keys, request signing, encryption and etc.
| Option name | Type | Description | Is required |
| --- | --- | --- | --- |
| - | String | Coder name to use | - |
| name | String | Coder name to use | - |
| arguments | Array | Arguments array for coder constructor | - |

Coder options. Coder provides 2 methods: `encode` and `decode` for converting request object to data and back.
```JavaScript
coder: 'Coder'
```
Coder name to use. Coders container is `Reqs.coders`.
```JavaScript
coder: {
    name: 'Coder',
    arguments: ['example key']
}
```
`name: 'Coder'`
Coder name to use. Coders container is `Reqs.coders`.
```JavaScript
this.coder = Reqs.coders[options.coder.name]
```
`arguments: ['example key']`
Arguments array for coder constructor.
```JavaScript
this.coder = new Coder(...options.coder.arguments)
```
Default coder have only one argument: `key`

#### Custom coder
Create coder:
```JavaScript
class MyCoder extends Reqs.Coder {
    constructor (key, arg1, argN) {
        super(key)
    }

    encode (request) {
        var data = 'encoded request'
        return data
    }

    decode (data) {
        var request = 'decoded request'
        return request
    }
}
```
Register coder:
```JavaScript
Reqs.addModule(MyCoder)
```
Use coder in options:
```JavaScript
coder: 'MyCoder'
```
```JavaScript
coder: {
    name: 'MyCoder',
    arguments: ['arg1', 'argN']
}
```
Or use in existing api instance immediatly whithout registration:
```JavaScript
var api = new Reqs()
api.use(MyCoder, 'key', 'arg1', 'argN')
```
Or:
```JavaScript
api.coder = new MyCoder('key', 'arg1', 'argN')
```

### `key`
```JavaScript
key: 'example key'
```
Is equal:
```JavaScript
coder: {
    name: 'Coder',
    arguments: ['example key']
}
```

### `protocol`
| Option name | Type | Description | Is required |
| --- | --- | --- | --- |
| - | String | Protocol name to use | - |
| name | String | Protocol name to use | - |
| arguments | Array | Arguments array for protocol constructor | - |

Protocol - class for converting from raw object to structured request objects. Protocol validate data types and Protocol is container for different requests constructors. Also, Protocol allow to convert requests from different sources and APIs. Default `Reqs.Protocol` contains different requests constructors used by Reqs internally for requests processing.
```JavaScript
protocol: 'Protocol'
```
Protocol name to use. Protocols container is `Reqs.protocols`.
```JavaScript
protocol: {
    name: 'Protocol',
    arguments: ['arg1', 'argN']
}
```
`name: 'Protocol'`
Protocol name to use. Protocols container is `Reqs.protocols`.
```JavaScript
this.protocol = Reqs.protocols[options.protocol.name]
```
`arguments: ['arg1', 'argN']`
Arguments array for protocol constructor.
```JavaScript
this.protocol = new Protocol(...options.protocol.arguments)
```
Default protocol doesn't have any arguments.

#### Custom Protocol
Protocol template:
```JavaScript
const Model = Reqs.Protocol.Model
// Original types used just as example
const types = Reqs.Protocol.types

class MyRequest {
    constructor(type) {
        this.type = type
    }
}

class MyMethod extends MyRequest {
    constructor(method, id, args, cbs) {
        super(types.method)
    }
}

class MyCallback extends MyRequest {
    constructor(id, args, cbs) {
        super(types.callback)
    }
}

class MyResolve extends MyRequest {
    constructor(id, resolve) {
        super(types.resolve)
    }
}

class MyReject extends MyRequest {
    constructor(id, reject) {
        super(types.reject)
    }
}

class MyError extends MyRequest {
    constructor(message = '', code = null, id) {
        super(types.error)
    }
}

class MyInfo extends MyRequest {
    constructor(id, events, methods) {
        super(types.info)
    }
}

class MyProtocol extends Reqs.Protocol {
    constructor() {
        super()
        // Incoming requests model
        this.model = {
            request: new Model({
                type: Model.required('Number')
            }),
            method: new Model({
            method: Model.required('String'),
                id: 'String',
                args: 'Array',
                cbs: 'Array'
            }),
            callback: new Model({
                id: Model.required('String'),
                args: 'Array',
                cbs: 'Array'
            }),
            promise: new Model({
                id: Model.required('String')
            }),
            error: new Model({
                message: Model.required('String'),
                code: 'Number',
                id: 'String'
            }),
            info: new Model({
                id: Model.required('String'),
                server: 'Array',
                client: 'Array'
            })
        }
    }

    parse(request) {
        this.model.request.validate(this, request)
        // Result of parsing must be Reqs internal requests types from Reqs.Protocol.<type>
        var r
        switch (request.type) {
            case types.method:
                this.model.method.validate(this, request)
                r = new Reqs.Protocol.Method(request.method, request.id, request.args, request.cbs)

            case types.callback:
                this.model.callback.validate(this, request)
                r = new Reqs.Protocol.Callback(request.id, request.args, request.cbs)

            case types.resolve:
                this.model.promise.validate(this, request)
                r = new Reqs.Protocol.Resolve(request.id, request.resolve)

            case types.reject:
                this.model.promise.validate(this, request)
                r = new Reqs.Protocol.Reject(request.id, request.reject)

            case types.error:
                this.model.error.validate(this, request)
                r = new Reqs.Protocol.Error(request.message, request.code, request.id)

            case types.info:
                this.model.info.validate(this, request)
                r = new Reqs.Protocol.Info(request.id, request.events, request.methods)
            default:
                r = this.throw(`Unknown request type: ${request.type}`)
        }
        return r
    }

    // In runtime Reqs will use this constructors for requests creation
    // Example:
    //   var r = new this.protocol.Method('method', args, cbs)
    MyProtocol.prototype.Method = MyMethod
    MyProtocol.prototype.Callback = MyCallback
    MyProtocol.prototype.Resolve = MyResolve
    MyProtocol.prototype.Reject = MyReject
    MyProtocol.prototype.Error = MyError
    MyProtocol.prototype.Info = MyInfo
}
```
Register protocol:
```JavaScript
Reqs.addModule(MyProtocol)
```
Use protocol in options:
```JavaScript
coder: 'MyProtocol'
```
```JavaScript
coder: {
    name: 'MyProtocol',
    arguments: ['arg1', 'argN']
}
```
Or use in existing api instance immediatly whithout registration:
```JavaScript
var api = new Reqs()
api.use(MyProtocol, 'key', 'arg1', 'argN')
```
Or:
```JavaScript
api.protocol = new MyProtocol('key', 'arg1', 'argN')
```

#### Constructor `Protocol.Model`
Used by `Protocol.parse` for request structure and data types validation.
Example use:
```JavaScript
const Model = Reqs.Protocol.Model
var models = {
    request: new Model({
        type: Model.required('Number')
    }),
    method: new Model({
        method: Model.required('String'),
        id: 'String',
        args: 'Array',
        cbs: 'Array'
    })
}
```
And validation in protocol's context:
```JavaScript
parse(request) {
    models.request.validate(protocol, request)
}
```

#### Constructor `Protocol.Method`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| methodName | String | Method name to call | Required |
| id | String | ID of the request | - |
| arguments | Array | Arguments | - |
| callbacks | Array | callbacks ID positions in arguments | - |

#### Constructor `Protocol.Callback`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| id | String | ID of the request | Required |
| arguments | Array | Arguments | - |
| callbacks | Array | callbacks ID positions in arguments | - |

#### Constructor `Protocol.Resolve`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| id | String | ID of the request | Required |
| result | Object | Result | - |

#### Constructor `Protocol.Reject`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| id | String | ID of the request | Required |
| reject | Object | Reject result error | - |

#### Constructor `Protocol.Error`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| message | String | error message | Required |
| code | Number | Error code | - |
| id | String | ID of the request |  - |

#### Constructor `Protocol.Info`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| id | String | ID of the request | Required |
| events | Array | List of events (for client's api) | - |
| methods | Array | List of methods (for client's api) | - |

### `session`
| Option name | Type | Description | Is required |
| --- | --- | --- | --- |
| arguments | String<br>Array | One session argument<br>Array of session arguments | - |

Session options. Session creation: `var session = api.new()`. Usually session used for multiple connections. For example - on server side it must be used if server provide API for multiple users. On client side session isn't required.

```JavaScript
session: {
    arguments: 'conn'
}
```
```JavaScript
session: {
    arguments: ['a', 'b', 'c']
}
```

#### `arguments`
Name - for one argument or array of names for several arguments. Allow to automatically attach additional info or objects to session instance.
`arguments: 'conn'`
```JavaScript
var session = api.new('conn')
session.conn === 'conn'
```
`arguments: ['a', 'b', 'c']`
```JavaScript
var session = api.new('a', 'b', 'c')
session.a === 'a'
session.b === 'b'
session.c === 'c'
```

### `newid`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| return | String | New ID for callback | Required |

Callbacks ID generator. By default - simple counter in `_id` property.
```JavaScript
newid: function() {
    return 'new id'
}
```

### `newpid`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| return | String | New ID for promise | Required |

Promises ID generator. By default - simple counter in `_pid` property.
```JavaScript
newpid: function() {
    return 'new pid'
}
```

## Reqs methods

Index:

[parse](#parse)<br>
[addMethod](#addMethod)<br>
[addMethods](#addMethods)<br>
[createMethod](#createMethod)<br>
[method](#method)<br>
[methodApply](#methodApply)<br>
[methodSync](#methodSync)<br>
[methodAsync](#methodAsync)<br>
[methodSyncApply](#methodSyncApply)<br>
[methodAsyncApply](#methodAsyncApply)<br>
[build](#build)

### `parse`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| data | String \| Buffer \| Whatever | Incoming raw data | Required |
| return | Depends on `send` and command in request |  | - |

Parse the request data. Data type is string/buffer/whatever from client/server.
```JavaScript
var result = api.parse(data)
```

### `addMethod`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| method | String | Method name | Required |
| return | Reqs | `this` | - |

Add method to `api.methods` list. Basically creates wrapper for `methodApply` with cached method name.
```JavaScript
api.addMethod('method')
```

### `addMethods`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| [methods](#methods) | - | - | Required |
| safe | Boolean | Don't oeverwrite existing methods (`true` by default) | - |

Add methods to `api.methods` list.

### `createMethod`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| method | String | Method name | Required |
| xt | Function | Function that returns arguments array for method | Required |
| mode | String | Method mode: 'async' \| 'sync' | - |
| xtThen | Function | Function for `promise.then` method | - |
| xtCatch | Function | Function for `promise.catch`  method | - |
| safe | Boolean | Don't oeverwrite existing methods (`true` by default) | - |

Create method to `api.methods` list with arguments preprocessor function and additional options. Creates wrapper for `methodApply` with cached method name and fixed mode, if `mode` argument presented.
```JavaScript
api.createMethod('method', xt, mode, xtThen, xtCatch)
```

### `method`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| method | String | Method name | Required |
| ...args | Any | Method arguments | - |

Call method with arguments. Mode depends on mode flag.
```JavaScript
api.method('method', ...args)
api.method('method', 'arg1', 'argN')
```

### `methodApply`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| method | String | Method name | Required |
| arguments | Array | Method arguments | - |

Call method with arguments array. Mode depends on mode flag.
```JavaScript
api.methodApply('method', ['arg1', 'argN'])
```

### `methodSync`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| method | String | Method name | Required |
| ...args | Any | Method arguments | - |

Call method with arguments in synchronous mode.
```JavaScript
api.methodSync('method', ...args)
api.methodSync('method', 'arg1', 'argN')
```

### `methodAsync`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| method | String | Method name | Required |
| ...args | Any | Method arguments | - |

Call method with arguments in asynchronous mode.
```JavaScript
api.methodAsync('method', ...args)
api.methodAsync('method', 'arg1', 'argN')
```

### `methodSyncApply`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| method | String | Method name | Required |
| arguments | Array | Method arguments | - |

Call method with arguments array in synchronous mode.
```JavaScript
api.methodSyncApply('method', ['arg1', 'argN'])
```

### `methodAsyncApply`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| method | String | Method name | Required |
| arguments | Array | Method arguments | - |

Call method with arguments array in asynchronous mode.
```JavaScript
api.methodAsyncApply('method', ['arg1', 'argN'])
```

### `build`
| Argument | Type | Description | Is required |
| --- | --- | --- | --- |
| cb | Function | Callback | - |

Request from server list of available events and methods.
```JavaScript
api.build()
```

---

# Develop

Build library:

    npm run build

Watch files:

    npm run watch

## What next?

1. Rewrite build script or use some other tool to get feature for building client with difference protocols and coders.
1. Add feature for detecting events arguments types (via comments parsing or options) and events arguments types validation.
1. OpenAPI / Swagger support.
1. (?) Add feature for requesting API documentation via API.
1. Feel free to suggest new features.
