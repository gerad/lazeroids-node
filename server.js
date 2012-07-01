(function() {
  var app, express, pub, io;

  express = require('express');

  pub = __dirname + '/public';

  app = express.createServer(express.compiler({
    src: pub,
    enable: ['sass']
  }), express["static"](pub), express.logger(), express.errorHandler({
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

  io = require('socket.io').listen(app);
  io.set('log level', 2);

  io.sockets.on('connection', function(socket) {
    socket.on('message', function(message) {
      socket.broadcast.emit('message', message);
    });
    socket.on('disconnect', function() {
      socket.broadcast.emit('message', JSON.stringify([['disconnect', socket.id]]));
    });
  });

}).call(this);
