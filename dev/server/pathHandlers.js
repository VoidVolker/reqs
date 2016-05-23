var Reqs = require('../../reqs.js');

var serv = new Reqs({
    SPI: {
        spi: function(a, cb){
            console.log('spi', a);
        }
    }
    , CPI: ['cpi']

    // API: {
    //     'ping': function(time, cb){
    //         console.log('ping', time);
    //         time = time ? Date.now()-time : 0 ;
    //         serv.CPI.pong(
    //             {
    //                 time: Date.now()
    //                 , ping: time
    //             }
    //         );
    //     }
    //     , 'pong': function(args, cb){
    //         console.log('/ pong', args);
    //     }, 'test': function(a, b){
    //         console.log('Test data from client:', a, b);
    //         if( this.cb ){
    //             console.log('Test from client have callback');
    //             this.cb('data', 'via', 'server', 'callback', function(a){
    //                 console.log('Client answer on CB: ', a);
    //             });
    //         }
    //         return ["test", "answer"];
    //     }
    // }
    // , CPI: ['ping', 'pong']
    , send: function(data){
        this.sendText(data);
    }
});

function rootHandle(str) { // this = connection
    try{
        console.info('    parsing string:', str);
        serv.parse(str, this);
    } catch(e){
        console.log('Reqs error: ', e);
    }
}

exports.root = rootHandle;