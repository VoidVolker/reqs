var wss = require('./wss')
    , pathHandlers = require('./pathHandlers')
    , handle = {}
    , srv
;

// Path handlers creating
// Установка обработчиков пути
handle['/'] = pathHandlers.root;

srv = wss.start(
    handle
    , 10001
    , 'localhost'
    , false
    , 1024000
);