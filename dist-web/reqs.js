this.Reqs=(function(module){/**
 * @file REQuest jSon interface for WebSockets, HTTP and any other protocols
 * @file [Russian] Библиотека для создания сетевых интерфейсов или API на основе json/bson через любой интерфейс
 */
/*

request type string: "function name" -> server["function name"]()

request type object: {
    CALL: "functionName"
    ARGS: [<any data>],
    [ CB: <cb_number> ]
}

request type object: {
    CALLBACK: "<cbid>"
    ARGS: [<any data>],
    [ CB: <cb_number> ]
}

examples:
{
    "ping": {
        "ARGS": [1448523645087]
    }
}

{
    "pong": {
        "ARGS": [{
            "time": 1448523645089,
            "ping": 1448523645087
        }]
    }
}

request ping example with CB:
{
    "ping": {
        "ARGS": [1448523501870],
        "CB": 0
    }
}

{
    "CB": {
        "ARGS": [
            0, {
                "time": 1448523501875,
                "ping": 1448523501870
            }
        ]
    }
}


var myapi1 = reqs.new({
    send: function(str){ // Function for sending requests
        // this === [connection object]
        this.sendText(str); // Websockets
    }
    , server: { // Server programming interface: actions for call's from other side
        'func1': function(arg){ // Mirror API way (server and client have same methods and functions)
            log.info('/command1 func1');
            return "some answer"; // same as: myapi1.client.func1("some answer")
        }
        , 'func2': function(arg, cb){  // Callback and promise way
            // cb === function | cb === undefined
            log.info('/command1 func2');
            cb(
                {other: "answer"}
                , function(arg, cb){ \\ Answer for this callback
            })
        }
    }
    , CPI: [ // Client programming interface: local user methods for other side
        'f3'
        , 'f4'
        , 'f5'
    ]
);

myapi1.parse('"json string with data from other side"', connection); // connection === [connection object] (will be transferd to server functions, sender, callbacks and promises). Also used to for callbacks
myapi1.client.f3({somekey: "somedata" });
myapi1.client.f4(123);
myapi1.client.f5("123");

var myapi2 = reqs.new({
    send: function(str){
        this.sendText(str);
    }
    , API: { // Mirror API - this methods names will be used to fill CPI with functions for answering
        'func1': function(arg[, cb]){
            log.info('/command1 func1');
        }
        , 'func2': function(arg[, cb]){
            log.info('/command1 func2');
        }
    }
);

*/

// ---------------------------------------------------------------------------------------------------
var rProto
    , t = Object.prototype.toString
    , clientProto
    , log = console
;

function isString(s){   return t.call(s) === '[object String]'; }
function isArray(s){    return t.call(s) === '[object Array]';  }
function isObject(s){   return t.call(s) === '[object Object]'; }
function isFunction(s){ return t.call(s) === '[object Function]'; }
function isNumber(s){   return s === s && (t.call(s) === '[object Number]') }
function typeOf(s) {    return t.call(s).slice(8, -1);}

function forObj(o, cb, cbThis){
    for(var key in o){
        if( o.hasOwnProperty(key) ){
            cb.call(cbThis, o[key], key, o);
        }
    }
}

function getInfo(method){
    if( this.cb !== undefined ){
        var res1 = []
            , res2 = []
        ;
        forObj( this.reqs.server, function(f, name){
            res1.push(name);
        });
        forObj( this.reqs.client, function(f, name){
            res2.push(name);
        });
        this.cb(res1, res2);
    }
}

/**
 * Parse the request in text format json
 * @param {string} request — the string from client/server
 * @param {object} conn — connection object
 */
/**
 * Разбор запроса в текстовом формате json
 * @param {string} request — строка запроса
 * @param {object} conn — объект connection
 */
function reqsParse(request, conn){ // JSON Request parser // Разбор входящего запроса
    var obj
        , fName
        , spi = this.server
        , params
        // , cpi = this.client
        , result
        , arr
        , xt
        , reqs = this
        , requestThis = {
            conn: conn
            , reqs: this
        }
        , cbid

    ;

    try     {   obj = JSON.parse(request);  }
    catch(e){
        this.error('Not valid JSON.');
        return;
    }

    // if( this.isValid(obj) ) { // Request validating

        // if( isString(obj) && spi.hasOwnProperty(obj) ){ // If it is string - try to execute as function

        //     if( this.isValid(obj) ) { // Request validating
        //         result = spi[obj].call(requestThis);
        //         if( result !== undefined && result === result ){ // Second - NaN check
        //             this.send.call(
        //                 conn,
        //                 JSON.stringify(
        //                     this.validate( { CALL: obj, ARGS: [result] } )
        //                 )
        //             );
        //         }
        //     } else {
        //         this.invalid(obj, conn);
        //     }
        //     return;

        // } else if( isObject(obj) ) { // if it is object - try to search functions and execute them...
        //     arr = [ obj ]
        // } else if( !isArray(obj) ){
        //     this.err404('reqs.parse() 404 unknown command: ' + obj.toString() );
        //     return;
        // }

    switch( typeOf(obj) ){
        case 'Object':
            arr = [ obj ];
            break;
        case 'Array':
            break;
        default:
            this.err404('reqs.parse() 404 unknown command: ' + obj.toString() );
            return;
    }

    for(xt in arr){

        if( this.isValid(obj) ) { // Request validating

            xt = arr[xt];
            if( xt.ARGS !== undefined && !isArray(xt.ARGS) ){
                this.err404('Wrong data type in property "ARGS". Data type is: ' + t.call(xt.ARGS) );
                return;
            }

            if(
                xt.hasOwnProperty('CALL')
            ){
                // ************************************************** //
                // Method handling //
                fName = xt.CALL;
                if ( fName !== undefined && isString(fName) && spi.hasOwnProperty(fName) ){

                    if( xt.CB !== undefined && isString(xt.CB) ){  // This function with callback
                        requestThis.cb = this.createCBWrapper(xt.CB, conn);
                        // requestThis.cb = function(args, cb){
                        //     var resp = {
                        //         CALLBACK: xt.CB
                        //     }
                        //     if( isFunction(cb) ){
                        //         resp.CB = createCallback(cb);
                        //     }
                        //     if( isArray(args) ){
                        //         resp.ARGS = args
                        //     }
                        //     this.send.call(conn, JSON.stringify(resp));
                        // }
                    }

                    result = spi[fName].apply(requestThis, xt.ARGS);

                    if( isArray( result ) ){
                        this.send.call(
                            conn,
                            JSON.stringify(
                                this.validate({ CALL: fName, ARGS: result })
                            )
                        );
                        return;
                    }

                } else {
                    this.err404('Method not found:' + fName);
                    return;
                }

            } else if( xt.hasOwnProperty('CALLBACK') ){
                // ************************************************** //
                // Callback handling //
                cbid = xt.CALLBACK;
                if( isString( cbid ) ){

                    if( xt.CB !== undefined && isString( xt.CB ) ){  // This callback with callback
                        result = this.CB(
                            cbid
                            , conn
                            , xt.ARGS
                            , this.createCBWrapper(xt.CB, conn)
                        );
                        if( isArray( result ) ){
                            this.send.call(
                                conn,
                                JSON.stringify(
                                    this.validate({ CALLBACK: xt.CB, ARGS: result })
                                )
                            );
                            return;
                        }
                        return;
                    } else {
                        this.CB(cbid, conn, xt.ARGS);
                        return;
                    }

                } else {
                    this.error('Wrong CALLBACK argument type.');
                    return;
                }

            } else if( xt.hasOwnProperty('INFO') ){

                if( xt.CB !== undefined && isString(xt.CB) ){
                    requestThis.cb = this.createCBWrapper(xt.CB, conn);
                    getInfo.call(requestThis, xt.INFO);
                }

            } else {
                this.err404('Missing root property "CALL" and "CALLBACK".', conn);
                return;
            }

        } else {
            this.invalid(obj, conn);
            return;
        }

    }

}

/**
 * Request is valid?
 * @param {object} obj — request object
 * @return {bool} bool — result of check
 */
function reqsIsValid(obj){ return true; }


/**
 * Request validate
 * @param {object} obj — request object
 * @return {object} obj — validated request object
 */
function reqsValidate(obj){ return obj; }

/**
 * Request invalid hamdler
 * @param {object} obj — request object
 * @param {object} conn — connection object
 */
function reqsInvalid(obj, conn){}

/**
 * Method for 404 error (function for this requset not found)
 * @param {string} msg — message fro client
 * @param {object} conn — connection object
 */
function err404(msg, conn){
    log.warn('Error 404! Resourse not found. Details: '+msg);
    log.warn(conn);
}

/**
 * Method for errors (function for this requset not found)
 * @param {string} msg — message from client
 * @param {object} conn — connection object
 */
function reqsError(msg, conn){
    // log.warn('Error! '+msg);
    // log.warn(conn);
    this.send(
        conn,
        JSON.stringify(
            this.validate({ ERROR: { MSG: msg } })
        )
    );
}

function getid(){
    if( this._id === Number.MAX_SAFE_INTEGER ){
        this._id = 1;
    }
    return this._id++;
}

function createCallback(cb){
    var id = this.cbid;   // Generate new cb id
    this.CB[id] = cb;
    return id.toString();
}

function createCBWrapper(cbid, conn ){
    var reqs = this;
    return function(){   // Create function-wrapper for API calls
        var req = { CALLBACK: cbid }
            , args = []
            , la = arguments[arguments.length-1]
            , i
        ;
        for(i in arguments){
            if( arguments.hasOwnProperty(i) ){
                args.push( arguments[i] );
            }
        }
        if( isFunction( la ) ){
            req.CB = reqs.createCallback( la );
            args = args.slice(0,-1);   // Removing callback from array
        }
        if( args.length > 0 ){
            req.ARGS = args;
        }
        reqs.send.call(  // Converting data to request format
            conn,
            JSON.stringify( reqs.validate(req) )
        );
    }
}

function createClient(reqs){
    if( reqs.client === undefined ){
        var send = reqs.send;
        reqs.client = function(fName, conn, args, cb){
            var req = { CALL: fName };
                // , args = {}
            if( isFunction(cb) ){
                req.CB = reqs.createCallback(cb);
            } else if( isFunction(conn) ){
                req.CB = reqs.createCallback(conn);
                conn === undefined;
            } else if( isFunction(args) ){
                req.CB = reqs.createCallback(args);
                args === undefined;
            }
            if( isArray( args ) ){
                req.ARGS = args;
            }
            send.call( // Converting data to request format
                conn,
                JSON.stringify( reqs.validate(req) )
            );
        }
    }
}

function clientFunction(fName){
    var reqs = this;
    return function(){   // Create function-wrapper for API calls
        var req = { CALL: fName }
            , args = []
            , cb = arguments[arguments.length-1]
            , i
        ;
        for(i in arguments){
            if( arguments.hasOwnProperty(i) ){
                args.push( arguments[i] );
            }
        }
        if( isFunction( cb ) ){
            req.CB = reqs.createCallback( cb );
            args = args.slice(0,-1);   // Removing callback from array
        }
        if( args.length > 0 ){
            req.ARGS = args;
        }
        // else if ( req.CB === undefined ) {
        //     req = fName;
        // }
        reqs.send.call( // Converting data to request format
            this,
            JSON.stringify( reqs.validate(req) )
        );
    }
}

function clientWrapper(fName, userXT){ // Caching function name (in other cases it will be lost)
    var reqs = this;
    return function(){
        arguments[arguments.length++] = function(){   // Create function-wrapper for API calls
            var req = { CALL: fName }
                , args = []
                , cb = arguments[arguments.length-1]
                , i
            ;
            for(i in arguments){
                if( arguments.hasOwnProperty(i) ){
                    args.push( arguments[i] );
                }
            }
            if( isFunction( cb ) ){
                req.CB = reqs.createCallback( cb );
                args = args.slice(0,-1);   // Removing callback from array
            }
            if( args.length > 0 ){
                req.ARGS = args;
            }
            // else if ( req.CB === undefined ) {
            //     req = fName;
            // }
            reqs.send.call( // Converting data to request format
                this,
                JSON.stringify( reqs.validate(req) )
            );
        };
        userXT.apply(this, arguments);
    }
}

function clientFunctionsAdd(reqs, apiList){ // This function is creates local API wrappers
    var i = 0
        , len
        , name
        , client = reqs.client
    ;
    if( isArray( apiList ) ) {

        // *** Array ***
        len = apiList.length;
        for(i; i<len; i++){
            name = apiList[i];
            if( client.hasOwnProperty(name) ){ continue; }
            client[name] = clientFunction.call(reqs, name);
        }

    } else if( isObject( apiList ) ) {

        // *** Object ***
        for( name in apiList ){
            if( apiList.hasOwnProperty(name) && client.hasOwnProperty(name) ){ continue; }
            client[name] = clientWrapper.call(reqs, name, apiList[name]);
        }

    }
}

/**
 * Создать новое апи, возвращает объект типа reqs, который содержит все необходимые методы и свойства
 * @param {object} options — опции
 */
/**
 * Create new API
 * @param {object} options
 */
function Reqs(options){ // Create new interface
    options = options || {};
    var localReqs = {
            server: options.server || {}
        }
        , client = options.client || []
        , isValid = options.isValid
        , validate = options.validate
    ;


    localReqs._id = 0; // Callback counter
    localReqs.__defineGetter__('cbid', getid);
    localReqs.__proto__ = rProto;

    localReqs.CB = function(id, conn, args, cb){
        var xt;
        if( localReqs.CB.hasOwnProperty(id) ){
            xt = localReqs.CB[id];
            delete localReqs.CB[id];
            return xt.apply( { conn: conn, cb: cb }, args );
        } else {
            localReqs.error('Wrong callback ID: ' + id);
        }
        // if( isArray(arr) && (arr.length > 0) ){
        //     var id = arr[0].toString();
        //     if( localReqs.CB.hasOwnProperty(id) ){
        //         localReqs.CB[id](arr[1]);
        //         delete localReqs.CB[id];
        //     }
        // }
    }

    if( isObject( options.API ) ){
        forObj(options.API, function(f, name){
            client.push(name);
            localReqs.server[name] = f;
        });
    }

    if( isFunction( options.send ) ){
        localReqs.send = options.send;
        createClient( localReqs );
        clientFunctionsAdd( localReqs, client );
    }

    // console.log('validate', validate,  typeOf( validate ));
    switch( typeOf( validate ) ){
        case 'String':
            localReqs.validate = function(o){
                o.validation = validate;
                return o;
            };
            break;
        case 'Function':
            localReqs.validate = validate;
    }

    // console.log('isValid', isValid,  typeOf( isValid ));
    switch( typeOf( isValid ) ){
        case 'String':
            localReqs.isValid = function(o){
                if( o.hasOwnProperty('validation') ){
                    return o.validation === isValid;
                } else {
                    return false;
                }
            };
            break;
        case 'Function':
            localReqs.isValid = isValid;
    }
    // console.log('localReqs', localReqs);
    return localReqs;
}

/**
 * Get API info
 * @param {object} conn
 * @param {object} methodName
 * @param {function} cb
 * @return {Reqs} this
 */
function requestInfo(conn, methodName, cb){
    if( isFunction(methodName) ){
        cb = methodName;
        methodName = '';
    } else if( isFunction(conn) ){
        cb = conn;
        methodName = '';
        conn = undefined;
    }
    if( !isFunction(cb) ){
        log.warn('reqs.info call without callback for data.');
        return;
    }
    this.send.call(
        conn,
        JSON.stringify(
            this.validate({ INFO: methodName, CB: this.createCallback(cb) })
        )
    );
    return this
}


/**
 * Build client API methods
 * @param {object} conn
 * @param {function} cb
 * @return {Reqs} this
 */
function build(conn, cb){
    var lreqs = this
        , newClient
    ;
    if( isFunction( conn ) ){
        cb = conn;
        conn = undefined;
    }

    function createApi(methods, events){
        clientFunctionsAdd(lreqs, methods);
        if( isFunction( cb ) ){
            cb(methods, events);
        }
    }

    this.send.call(
        conn,
        JSON.stringify(
            this.validate({
                INFO: ''
                , CB:
                    this.createCallback( createApi )
            })
        )
    );
    return this;
}

module.exports = Reqs;
rProto = {
    'parse': reqsParse
    , 'err404': err404
    , 'error': reqsError
    , 'info': requestInfo
    , 'validate': reqsValidate
    , 'isValid': reqsIsValid
    , 'invalid': reqsInvalid
    , 'createCallback': createCallback
    , 'createCBWrapper': createCBWrapper
    , 'clientFunction': clientFunction
    , 'clientWrapper': clientWrapper
    , 'build': build
};
return module.exports;})(this.module || {})