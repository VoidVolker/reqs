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
});

function rootHandle(str) {
    try{
        console.info('    parsing string:', str);
        api.parse(str, this); // this - is connection onject
    } catch(e){
        console.log('Reqs error: ', e);
    }
}

exports.root = rootHandle;
