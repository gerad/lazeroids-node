(function() {
  var app, express, pub, socket;
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
  socket = require('socket.io').listen(app);
  socket.on('connection', function(client) {
    client.on('message', function() {
      return socket.broadcast(message);
    });
    return client.on('disconnect', function() {
      return client.broadcast([['disconnect', client.sessionId]]);
    });
  });
})();
