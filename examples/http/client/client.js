// Generated by CoffeeScript 2.5.1
var App;

App = class App {
  constructor($1) {
    var app;
    this.$ = $1;
    this.httpApiUrl = '/api';
    app = this;
    this.api = new Reqs({
      events: {
        pong: function(t1, time) {
          var t2;
          t2 = Date.now() - time;
          return console.log(`Event: 'Pong'. ping ${t1} + ${t2} = ${t1 + t2}`);
        }
      },
      methods: [
        {
          cbPing: function() {
            return [
              Date.now(),
              function(t1,
              time) {
                var t2;
                t2 = Date.now() - time;
                return console.log(`Ping with callback result: ping ${t1} + ${t2} = ${t1 + t2}`);
              }
            ];
          },
          syncPing: function() {
            return [Date.now()]; // Return array with arguments for method.
          },
          asyncPing: {
            mode: 'async',
            method: function() {
              return [Date.now()]; // Return array with arguments for method (arguments array for method). Returns promise.
            },
            // Optional function for promise.then() method
            then: function(result) {
              var t1,
        t2,
        time;
              t1 = result[0];
              time = result[1];
              t2 = Date.now() - time;
              return console.log(`asyncPing result: ${t1} + ${t2} = ${t1 + t2}`);
            },
            // Optional function for promise.catch() method
            catch: function(err) {
              return console.error('asyncPing error:',
        err);
            }
          },
          // Example use:
          // app.api.methods.asyncPing()
          //   .then(function(result) {
          //       var t1 = result[0], time = result[1], t2 = Date.now()-time;
          //       console.log(`asyncPing result: ${t1} + ${t2} = ${t1 + t2}`);
          //   }).catch(function(err) { console.error('asyncPing error:', err) })
          history: function() {
            return [
              function(channels) {
                return app.setHistory(channels);
              }
            ];
          }
        },
        'message',
        'createChannel'
      ],
      send: function(data) { // Function for sending data
        console.log('==> Request:', data);
        app.apiPost(data);
      },
      session: {
        arguments: ['ws']
      },
      // coder:
      //     name: 'Coder'
      //     arguments: ['example key']
      key: 'example key',
      mode: 'sync' // Methods call mode for all methods whithout async/sync flag
    });
  }

  apiPost(data) {
    return $.ajax({
      url: this.httpApiUrl,
      type: 'POST',
      data: data,
      contentType: 'application/json; charset=utf-8',
      dataType: 'text',
      success: (result) => {
        var r;
        console.log('<== Response:', result);
        if (result) {
          return r = this.api.parse(result);
        } else {
          return console.error('Post response is undefined');
        }
      }
    });
  }

  sendAsyncPing() {
    return APP.api.methods.asyncPing().then(function(result) {
      var t1, t2, time;
      t1 = result[0];
      time = result[1];
      t2 = Date.now() - time;
      return console.log(`asyncPing result: ${t1} + ${t2} = ${t1 + t2}`);
    }).catch(function(err) {
      return console.error('asyncPing error:', err);
    });
  }

};

$(function() {
  return window.APP = new App();
});

//# sourceMappingURL=client.js.map