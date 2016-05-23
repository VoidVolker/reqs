/**
 * @file REQuest jSon interface for WebSockets, HTTP and any other protocols
 * @file [Russian] Библиотека для создания сетевых интерфейсов или API на основе json/bson через любой интерфейс
 */
/*

request type string: "function name" -> SPI["function name"]()

request type object: {
    CALL: "functionName"
    ARGS: <any data type>,
    [ CB: <cb_number> ]
}

request type object: {
    CALLBACK: "<cbid>"
    ARGS: <any data type>,
    [ CB: <cb_number> ]
}

examples:
{
    "ping": {
        "ARG": 1448523645087
    }
}

{
    "pong": {
        "ARG": {
            "time": 1448523645089,
            "ping": 1448523645087
        }
    }
}

request ping example with CB:
{
    "ping": {
        "ARG": 1448523501870,
        "CB": 0
    }
}

{
    "CB": {
        "ARG": [
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
    , SPI: { // Server programming interface: actions for call's from other side
        'func1': function(arg){ // Mirror API way (server and client have same methods and functions)
            log.info('/command1 func1');
            return "some answer"; // same as: myapi1.CPI.func1("some answer")
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

myapi1.parse('"json string with data from other side"', connection); // connection === [connection object] (will be transferd to SPI functions, sender, callbacks and promises). Also used to for callbacks
myapi1.CPI.f3({somekey: "somedata" });
myapi1.CPI.f4(123);
myapi1.CPI.f5("123");

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
function isNumber(s){ return s === s && (t.call(s) === '[object Number]') }
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
        forObj( this.reqs.SPI, function(f, name){
            res1.push(name);
        });
        forObj( this.reqs.CPI, function(f, name){
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
        , spi = this.SPI
        , params
        // , cpi = this.CPI
        , result
        , arr
        , xt
        , localReqs = this
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

    if( this.validate(obj) ) { // Request validating

        if( isString(obj) && spi.hasOwnProperty(obj) ){ // If it is string - try to execute as function

            result = spi[obj].call(requestThis);
            if( result !== undefined && result === result ){ // Second - NaN check
                this.send.call(conn, JSON.stringify( { CALL: obj, ARGS: [result] } ) );
            }

        } else if( isObject(obj) ) { // if it is object - try to search functions and execute them...
            arr = [ obj ]
        } else if( !isArray(obj) ){
            this.err404('reqs.parse() 404 unknown command: ' + obj.toString() );
            return;
        }

        for(xt in arr){
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
                        requestThis.cb = localReqs.createCBWrapper(xt.CB, conn);
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
                        //     localReqs.send.call(conn, JSON.stringify(resp));
                        // }
                    }

                    result = spi[fName].apply(requestThis, xt.ARGS);

                    if( isArray( result ) ){
                        localReqs.send.call(conn, JSON.stringify( { CALL: fName, ARGS: result } ) );
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
                        result = localReqs.CB(
                            cbid
                            , conn
                            , xt.ARGS
                            , localReqs.createCBWrapper(xt.CB, conn)
                        );
                        if( isArray( result ) ){
                            localReqs.send.call(conn, JSON.stringify( { CALLBACK: xt.CB, ARGS: result } ) );
                            return;
                        }
                        return;
                    } else {
                        localReqs.CB(cbid, conn, xt.ARGS);
                        return;
                    }

                } else {
                    this.error('Wrong CALLBACK argument type.');
                    return;
                }

            } else if( xt.hasOwnProperty('INFO') ){

                if( xt.CB !== undefined && isString(xt.CB) ){
                    requestThis.cb = localReqs.createCBWrapper(xt.CB, conn);
                    getInfo.call(requestThis, xt.INFO);
                }

            } else {
                this.err404('Missing root property "CALL" and "CALLBACK".');
                return;
            }

        }

    } else {
        this.error('reqs.parse() Not valid object');
        return;
    }
}

function reqsValidate(obj){
    return true;
}

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
            { ERROR:
                { MSG: msg }
            }
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
    var localReqs = this;
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
            req.CB = localReqs.createCallback( la );
            args = args.slice(0,-1);   // Removing callback from array
        }
        if( args.length > 0 ){
            req.ARGS = args;
        }
        localReqs.send.call(conn, JSON.stringify(req) ); // Converting data to request format
    }
}

function createWrapper(fName, sender, conn){
    var localReqs = this;
    return function(){   // Create function-wrapper for API calls
        var req = { CALL: fName }
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
            req.CB = localReqs.createCallback( la );
            args = args.slice(0,-1);   // Removing callback from array
        }
        if( args.length > 0 ){
            req.ARGS = args;
        } else if ( req.CB === undefined ) {
            req = fName;
        }
        localReqs.send.call(conn, JSON.stringify(req) ); // Converting data to request format
    }
}

function reqsClient(reqs, cpi, sender){ // This function is creates local API wrappers
    var client
        , i = 0
        , len
    ;

    client = function(fName, conn, args, cb){
        var req = { CALL: fName }
            , args = {}
        ;
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
        sender.call(conn, JSON.stringify(req)); // Converting data to request format
    }

    // cpi.push('CB');
    len = cpi.length;

    for(i; i<len; i++){
        client[cpi[i]] = (function(fName){   // Caching function name (in other cases it will be lost)
            return function(){   // Create function-wrapper for API calls
                var req = { CALL: fName }
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
                } else if ( req.CB === undefined ) {
                    req = fName;
                }
                // console.log( 'CPI CALL: ' + fName, arguments, args, la);
                sender.call(this, JSON.stringify(req) ); // Converting data to request format
            }
        })(cpi[i]);
    }

    return client;
}

/**
 * Create new API
 * @param {object} options
 */
/**
 * Создать новое апи, возвращает объект типа reqs, который содержит все необходимые методы и свойства
 * @param {object} options — опции
 */
function reqs(options){ // Create new interface
    options = options || {};
    var localReqs = {
            SPI: options.SPI || {}
        }
        , cpi = options.CPI || []
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
            cpi.push(name);
            localReqs.SPI[name] = f;
        });
    }

    if( isFunction( options.send ) ){
        localReqs.CPI = reqsClient(localReqs, cpi, options.send );
        localReqs.send = options.send;
    }

    return localReqs;
}

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
    this.send.call(conn, JSON.stringify({ INFO: methodName, CB: this.createCallback(cb) }));
}


function makeApi(conn, cb){
    var lreqs = this;
    if( isFunction( conn ) ){
        cb = conn;
        conn = undefined;
    }

    function createApi(methods, events){
        lreqs.CPI = reqsClient(lreqs, methods, lreqs.send);
        if( isFunction( cb ) ){
            cb(methods, events);
        }
    }

    this.send.call(
        conn, JSON.stringify({
            INFO: ''
            , CB:
                this.createCallback( createApi )
        })
    );
}

module.exports = reqs;
rProto = {
    'parse': reqsParse
    , 'err404': err404
    , 'error': reqsError
    , 'info': requestInfo
    , 'validate': reqsValidate
    , 'createCallback': createCallback
    , 'createCBWrapper': createCBWrapper
    , 'createWrapper': createWrapper
    , 'make': makeApi
};
