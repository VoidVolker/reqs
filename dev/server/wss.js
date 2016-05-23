var ws = require('nodejs-websocket')
    , ERR_404_CODE = 4404
    , ERR_404_STR = 'Not found'
    , util = require('util')
;


function start(handle, port, host, secure, buf) {
    console.info('Server start at host:', host+':'+port );

    // Set max size of buffer
    // Ограничиваем размер буфера - во избежание утечек памяти и атак типа "переполнение буфера"
    ws.setMaxBufferLength( buf );

    return ws.createServer(

        // Set secure flag for socket (SSL/TLS)
        // Устанавливаем флаг бехопасности для сокета
        { secure: secure }

        // Connections handling
        // Обрабботка соединений
        , function (conn) {
            console.log('--- New connection! conn.path: ' + conn.path);

            // Log connection closing
            // Лог закрытия соединения
            conn.on('close', function (code, reason) {
                console.log('--- Connection closed', code, reason);
            });

            // Conection errors handling (necessarily!)
            // Обработка ошибок соединения (обязательно!)
            conn.on('error', function(err){

                // This error happens when connections lost
                // Эта ошибка происходит при обрыве связи
                if( err.code === "ECONNRESET" ) {
                   // console.error('--- Connection close error ECONNRESET');
                } else {
                   console.error('--- Connection error: ', err)
                }

            });

            // Connection path handling
            // Обработка пути соединения
            try{

                if( util.isFunction( handle[conn.path] ) ){

                    // Here is handlers run
                    // Запуск обработчиков пути
                    conn.on('text', handle[conn.path] );

                } else {

                    conn.close(ERR_404, ERR_404_STR);
                }

            } catch(e){
                console.error('--- Error while processing path "'+conn.path+'"', e);
            }

        // Run WS server
        // Запуск WS сервера
        }).listen( port, host );
}

exports.start = start;

