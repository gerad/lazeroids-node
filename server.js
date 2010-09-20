(function() {
  var app, comet, express, pub;
  express = require('express');
  pub = __dirname + '/public';
  app = express.createServer(express.compiler({
    src: pub,
    enable: ['sass']
  }), express.staticProvider(pub), express.logger(), express.errorHandler({
    dumpExceptions: true,
    showStack: true
  }));
  app.get('/', function(req, res) {
    return res.render('index.jade');
  });
  app.get('/lazeroids.js', function(req, res) {
    return res.sendfile('lazeroids.js');
  });
  app.listen(process.env.PORT || 8000);
  comet = require('socket.io').listen(app, function(client) {
    client.on('message', function() {
      return comet.broadcast(message);
    });
    return client.on('disconnect', function() {
      return client.broadcast([['disconnect', client.sessionId]]);
    });
  });
})();
