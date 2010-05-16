(function(){
  var server, sio;
  require.paths.unshift('./lib/express/lib');
  require('express');
  // required  for views
  configure(function() {
    return set('root', __dirname);
  });
  get('/', function() {
    return this.render('index.html.haml');
  });
  server = run(parseInt(process.env.PORT || 8000), null);
  // handle web sockets
  sio = require('./lib/socket.io/lib/socket.io');
  sio.listen(server, {
    resource: '/ws',
    transports: 'websocket htmlfile xhr-multipart xhr-polling'.split(' ')
  });
})();
